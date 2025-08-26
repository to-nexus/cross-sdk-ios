import Foundation
import CrossAppKit
import Combine

/// 체인 관리를 담당하는 클래스
public class CrossChainManager: ObservableObject {

    // MARK: - Properties

    /// 현재 선택된 체인
    @Published public private(set) var currentChain: CrossChain?

    /// 지원하는 모든 체인
    public let supportedChains: [CrossChain] = CrossChain.allCases

    /// 체인 변경 델리게이트
    public weak var delegate: CrossChainManagerDelegate?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // AppKit 설정 후에 초기 체인 설정됨
    }

    // MARK: - Public Methods

    /// AppKit 설정 후 초기화
    internal func setupAfterAppKitConfiguration() {
        setupInitialChain()
        setupAppKitEventSubscription()
    }

    /// 체인 변경
    /// - Parameter chain: 변경할 체인
    public func switchChain(to chain: CrossChain) async throws {
        guard let selectedChain = AppKit.instance.getSelectedChain() else {
            throw CrossSDKError.walletNotConnected
        }

        // 이미 같은 체인이면 리턴
        if currentChain == chain {
            return
        }

        let targetChain = convertToChain(chain)

        do {
            try await performChainSwitch(from: selectedChain, to: targetChain)
            currentChain = chain
            delegate?.chainDidChange(to: chain)
        } catch {
            delegate?.chainSwitchDidFail(error: error)
            throw error
        }
    }

    /// 체인이 지원되는지 확인
    /// - Parameter chain: 확인할 체인
    /// - Returns: 지원 여부
    public func isChainSupported(_ chain: CrossChain) -> Bool {
        return supportedChains.contains(chain)
    }

    /// 체인 ID로 CrossChain 찾기
    /// - Parameter chainId: 체인 ID
    /// - Returns: CrossChain (없으면 nil)
    public func findChain(by chainId: String) -> CrossChain? {
        return CrossChain(rawValue: chainId)
    }

    // MARK: - Immediate Chain Switch Methods

        /// 즉시 체인 변경 (지갑 승인 불필요)
    /// - Parameter chain: 변경할 체인
    /// - Note: 지갑이 모든 체인을 지원한다고 가정하고 즉시 성공 처리
    public func switchChainImmediately(to chain: CrossChain) {
        print("🚀 CrossChainManager: Switching chain immediately to \(chain.name)")

        // 이미 같은 체인이면 리턴
        guard currentChain != chain else {
            print("✅ CrossChainManager: Already on \(chain.name)")
            return
        }

        // 즉시 로컬 상태 업데이트
        currentChain = chain

        print("✅ CrossChainManager: Local chain updated to \(chain.name)")

        // 델리게이트 알림 (즉시 변경)
        delegate?.chainDidChangeImmediately(to: chain)

        // AppKit을 통해 chainChanged 이벤트 발생 (지갑에서 실제로 이벤트를 보낸 것처럼 처리)
        triggerChainChangedEventViaAppKit(to: chain)

        print("✅ CrossChainManager: Immediate chain switch completed")
    }

    /// AppKit을 통해 chainChanged 이벤트를 발생시킴
    /// - Parameter chain: 변경된 체인
    private func triggerChainChangedEventViaAppKit(to chain: CrossChain) {
        print("🎭 CrossChainManager: Triggering chainChanged event via AppKit for \(chain.name)")

        // AppKit을 통해 chainChanged 이벤트 발생
        // 이는 지갑에서 실제로 chainChanged 이벤트를 보낸 것과 동일한 효과
        AppKit.instance.triggerChainChangedEvent(chainId: chain.rawValue)

        print("✅ CrossChainManager: chainChanged event triggered via AppKit")
    }

    // MARK: - Private Methods

    private func setupInitialChain() {
        // AppKit에서 현재 선택된 체인 가져오기
        if let selectedChain = AppKit.instance.getSelectedChain(),
           let crossChain = CrossChain(rawValue: selectedChain.chainReference) {
            currentChain = crossChain
            print("🔧 CrossChainManager: Initial chain set to \(crossChain.name)")
        }
    }
    
    /// AppKit의 체인 변경 이벤트 구독 설정
    private func setupAppKitEventSubscription() {
        print("🔧 CrossChainManager: Setting up AppKit event subscription")
        
        // AppKit의 sessionEventPublisher 구독하여 chainChanged 이벤트 감지
        AppKit.instance.sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event, _, _ in
                guard let self = self else { return }
                
                switch event.name {
                case "chainChanged":
                    self.handleChainChangedFromAppKit(event)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        print("✅ CrossChainManager: AppKit event subscription setup completed")
    }
    
    /// AppKit에서 온 chainChanged 이벤트 처리
    private func handleChainChangedFromAppKit(_ event: Session.Event) {
        guard let chainReference = try? event.data.get(Int.self) else {
            print("⚠️ CrossChainManager: Failed to parse chainReference from chainChanged event")
            return
        }
        
        let chainReferenceString = String(chainReference)
        guard let crossChain = CrossChain(rawValue: chainReferenceString) else {
            print("⚠️ CrossChainManager: Unknown chain reference: \(chainReferenceString)")
            return
        }
        
        print("🔄 CrossChainManager: Received chainChanged event from AppKit - \(crossChain.name)")
        
        // 현재 체인과 다른 경우에만 업데이트
        if currentChain != crossChain {
            currentChain = crossChain
            delegate?.chainDidChange(to: crossChain)
            print("✅ CrossChainManager: Chain updated to \(crossChain.name) from AppKit event")
        } else {
            print("ℹ️ CrossChainManager: Chain already set to \(crossChain.name), no update needed")
        }
    }

    private func convertToChain(_ crossChain: CrossChain) -> Chain {
        return Chain(
            chainName: crossChain.name,
            chainNamespace: "eip155",
            chainReference: crossChain.rawValue,
            requiredMethods: [
                "personal_sign",
                "eth_signTypedData",
                "eth_sendTransaction"
            ],
            optionalMethods: [
                "wallet_switchEthereumChain",
                "wallet_addEthereumChain"
            ],
            events: [
                "chainChanged",
                "accountsChanged"
            ],
            token: Chain.Token(
                name: crossChain.symbol,
                symbol: crossChain.symbol,
                decimal: 18
            ),
            rpcUrl: crossChain.rpcUrl,
            blockExplorerUrl: crossChain.explorerUrl,
            imageId: crossChain.imageId
        )
    }

    private func performChainSwitch(from: Chain, to: Chain) async throws {
        guard let chainIdNumber = Int(to.chainReference) else {
            throw CrossSDKError.invalidChain
        }

        let chainHex = String(format: "%X", chainIdNumber)

        guard let session = AppKit.instance.getSessions().first else {
            throw CrossSDKError.walletNotConnected
        }

        // 체인 변경 요청
        try await AppKit.instance.request(params:
            .init(
                topic: session.topic,
                method: "wallet_switchEthereumChain",
                params: AnyCodable([AnyCodable(ChainSwitchParams(chainId: "0x\(chainHex)"))]),
                chainId: .init(from.id)!
            )
        )
    }
}

/// 체인 변경 파라미터
private struct ChainSwitchParams: Codable {
    let chainId: String
}
