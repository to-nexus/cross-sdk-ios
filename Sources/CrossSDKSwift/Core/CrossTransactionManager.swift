import Foundation
import CrossAppKit
import Combine

/// 트랜잭션 및 서명을 관리하는 클래스
public class CrossTransactionManager: ObservableObject {

    // MARK: - Properties

    /// 트랜잭션 결과를 받기 위한 델리게이트
    public weak var delegate: CrossTransactionManagerDelegate?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var pendingRequests: [String: (Result<String, Error>) -> Void] = [:]

    // MARK: - Initialization

    init() {
        // AppKit 설정 후에 응답 observer 설정됨
    }

    // MARK: - Public Methods

    /// AppKit 설정 후 초기화
    internal func setupAfterAppKitConfiguration() {
        setupResponseObserver()
    }

    /// 메시지 서명
    /// - Parameter message: 서명할 메시지
    /// - Returns: 서명된 결과
    public func signMessage(_ message: String) async throws -> String {
        guard let wallet = getCurrentWallet() else {
            throw CrossSDKError.walletNotConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                let requestId = UUID().uuidString
                do {
                    let request = W3MJSONRPC.personal_sign(
                        address: wallet.address,
                        message: message
                    )

                    pendingRequests[requestId] = { result in
                        continuation.resume(with: result)
                    }

                    try await AppKit.instance.request(request)
                    
                    // 🔥 서명 요청 후 지갑 앱으로 이동
                    await navigateToWalletForSigning()
                    
                } catch {
                    pendingRequests.removeValue(forKey: requestId)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 트랜잭션 전송
    /// - Parameter params: 트랜잭션 파라미터
    /// - Returns: 트랜잭션 해시
    public func sendTransaction(_ params: CrossTransactionParams) async throws -> String {
        guard let wallet = getCurrentWallet() else {
            throw CrossSDKError.walletNotConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let request = W3MJSONRPC.eth_sendTransaction(
                        from: wallet.address,
                        to: params.to,
                        value: convertToWei(params.value),
                        data: params.data ?? "0x",
                        nonce: nil,
                        gas: params.gasLimit,
                        gasPrice: params.gasPrice,
                        maxFeePerGas: nil,
                        maxPriorityFeePerGas: nil,
                        gasLimit: params.gasLimit,
                        chainId: wallet.chain.rawValue
                    )

                    let requestId = UUID().uuidString
                    pendingRequests[requestId] = { result in
                        continuation.resume(with: result)
                    }

                    try await AppKit.instance.request(request)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 트랜잭션 서명 (전송하지 않음)
    /// - Parameter params: 트랜잭션 파라미터
    /// - Returns: 서명된 트랜잭션
    public func signTransaction(_ params: CrossTransactionParams) async throws -> String {
        guard let wallet = getCurrentWallet() else {
            throw CrossSDKError.walletNotConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let request = W3MJSONRPC.eth_signTransaction(
                        from: wallet.address,
                        to: params.to,
                        value: convertToWei(params.value),
                        data: params.data ?? "0x",
                        nonce: nil,
                        gas: params.gasLimit,
                        gasPrice: params.gasPrice,
                        maxFeePerGas: nil,
                        maxPriorityFeePerGas: nil,
                        gasLimit: params.gasLimit,
                        chainId: wallet.chain.rawValue
                    )

                    let requestId = UUID().uuidString
                    pendingRequests[requestId] = { result in
                        continuation.resume(with: result)
                    }

                    try await AppKit.instance.request(request)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 타입이 지정된 데이터 서명 (EIP-712)
    /// - Parameters:
    ///   - data: 서명할 타입 데이터
    ///   - address: 서명할 주소
    /// - Returns: 서명 결과
    public func signTypedData(_ data: String, address: String? = nil) async throws -> String {
        guard let wallet = getCurrentWallet() else {
            throw CrossSDKError.walletNotConnected
        }

        let signerAddress = address ?? wallet.address

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // eth_signTypedData 요청 생성
                    guard let session = AppKit.instance.getSessions().first,
                          let chain = AppKit.instance.getSelectedChain(),
                          let blockchain = Blockchain(namespace: chain.chainNamespace, reference: chain.chainReference) else {
                        throw CrossSDKError.walletNotConnected
                    }

                    let requestId = UUID().uuidString
                    pendingRequests[requestId] = { result in
                        continuation.resume(with: result)
                    }

                    try await AppKit.instance.request(params:
                        .init(
                            topic: session.topic,
                            method: "eth_signTypedData",
                            params: AnyCodable([signerAddress, data]),
                            chainId: blockchain
                        )
                    )
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func setupResponseObserver() {
        AppKit.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleResponse(response)
            }
            .store(in: &cancellables)
    }

    private func handleResponse(_ response: W3MResponse) {
        print("🔄 CrossTransactionManager: Handling response: \(response)")
        
        // 응답 처리 로직
        switch response.result {
        case .response(let result):
            if let stringResult = result.value as? String {
                print("✅ CrossTransactionManager: Success response: \(stringResult)")
                
                // 🔥 첫 번째 대기 중인 요청에만 응답 전달 (FIFO)
                if let (requestId, completion) = pendingRequests.first {
                    completion(.success(stringResult))
                    pendingRequests.removeValue(forKey: requestId)
                    delegate?.transactionDidSucceed(result: stringResult)
                }
            }
        case .error(let error):
            print("❌ CrossTransactionManager: Error response: \(error)")
            
            // 🔥 첫 번째 대기 중인 요청에만 에러 전달 (FIFO)
            let nsError = NSError(domain: "CrossSDKSwift", code: error.code, userInfo: [NSLocalizedDescriptionKey: error.message])
            if let (requestId, completion) = pendingRequests.first {
                completion(.failure(nsError))
                pendingRequests.removeValue(forKey: requestId)
                delegate?.transactionDidFail(error: nsError)
            }
        }
    }
    
    /// 서명을 위해 지갑 앱으로 이동
    @MainActor
    private func navigateToWalletForSigning() async {
        print("🚀 CrossTransactionManager: Navigating to wallet for signing")
        
        // AppKit의 launchCurrentWallet() 사용 (이미 연결된 지갑 앱 열기)
        AppKit.instance.launchCurrentWallet()
        
        print("✅ CrossTransactionManager: Launched current wallet via AppKit")
    }

    private func getCurrentWallet() -> CrossWallet? {
        guard let session = AppKit.instance.getSessions().first,
              let account = session.namespaces.values.first?.accounts.first else {
            return nil
        }

        let address = account.address
        let chainId = account.blockchain.reference

        guard let chain = CrossChain(rawValue: chainId) else {
            return nil
        }

        return CrossWallet(address: address, chain: chain)
    }

    private func convertToWei(_ ethValue: String) -> String {
        guard let ethDouble = Double(ethValue) else {
            return "0"
        }

        let weiValue = ethDouble * pow(10, 18)
        return String(format: "%.0f", weiValue)
    }
}

/// CrossTransactionManager의 이벤트를 처리하는 델리게이트
public protocol CrossTransactionManagerDelegate: AnyObject {
    /// 트랜잭션이 성공했을 때 호출
    func transactionDidSucceed(result: String)

    /// 트랜잭션이 실패했을 때 호출
    func transactionDidFail(error: Error)
}
