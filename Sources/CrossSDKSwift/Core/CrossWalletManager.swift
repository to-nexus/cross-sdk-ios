import Foundation
import CrossAppKit
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// 지갑 연결을 관리하는 클래스
public class CrossWalletManager: ObservableObject {

    // MARK: - Properties

    /// 현재 연결 상태
    @Published public private(set) var connectionState: CrossWalletConnectionState = .disconnected

    /// 현재 연결된 지갑 (연결된 경우)
    public var connectedWallet: CrossWallet? {
        if case .connected(let wallet) = connectionState {
            return wallet
        }
        return nil
    }

    /// 연결 여부
    public var isConnected: Bool {
        if case .connected = connectionState {
            return true
        }
        return false
    }

    /// 델리게이트
    public weak var delegate: CrossWalletManagerDelegate?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // AppKit observers는 configure 호출 후에 설정됨
    }

    // MARK: - Public Methods

    /// AppKit 설정 후 observers 초기화
    internal func setupAfterAppKitConfiguration() {
        print("🔧 CrossWalletManager: Setting up after AppKit configuration")
        setupAppKitObservers()
        
        // 기존 세션이 있는지 확인하고 상태 복원
        checkAndRestoreExistingSession()
        print("✅ CrossWalletManager: Setup completed")
    }

    /// 지갑 연결 시작
    public func connectWallet() async throws {
        updateConnectionState(.connecting)

        do {
            guard let uri = try await AppKit.instance.connect(walletUniversalLink: nil) else {
                throw CrossSDKError.invalidURL
            }
            
            let deeplinkUriString = "crossx://wc?uri=\(uri.deeplinkUri)"
            
            guard let deepLinkURL: URL = URL(string: deeplinkUriString) else {
                print("❌ CrossWalletManager: Failed to create deeplink URL")
                updateConnectionState(.error(CrossSDKError.invalidURL))
                throw CrossSDKError.invalidURL
            }
            
            print("🔗 CrossWalletManager: Opening deeplink URL: \(deeplinkUriString)")
            
            // 딥링크 URL 호출하여 지갑 앱 열기
            await openURL(deepLinkURL)
            
        } catch {
            updateConnectionState(.error(error))
            throw error
        }
    }

    /// 지갑 연결용 딥링크 URL 생성 (QR 코드용)
    public func generateConnectURL() async throws -> String {
        do {
            guard let uri = try await AppKit.instance.connect(walletUniversalLink: nil) else {
                throw CrossSDKError.invalidURL
            }
            
            let deeplinkUriString = "crossx://wc?uri=\(uri.deeplinkUri)"
            
            print("🔗 CrossWalletManager: Generated connect URL: \(deeplinkUriString)")
            
            return deeplinkUriString
            
        } catch {
            print("❌ CrossWalletManager: Failed to generate connect URL: \(error)")
            throw error
        }
    }

    /// 지갑 연결 해제
    public func disconnectWallet() async throws {
        guard let session = CrossSDKSwift.shared.getCurrentSession() else {
            updateConnectionState(.disconnected)
            return
        }

        do {
            try await AppKit.instance.disconnect(topic: session.topic)
            updateConnectionState(.disconnected)
        } catch {
            updateConnectionState(.error(error))
            throw error
        }
    }

    // MARK: - Private Methods

    private func setupAppKitObservers() {
        // 세션 정착 이벤트 관찰
        AppKit.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.handleSessionSettled(session)
            }
            .store(in: &cancellables)

        // 세션 삭제 이벤트 관찰
        AppKit.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (topic, reason) in
                self?.handleSessionDeleted(topic: topic, reason: reason)
            }
            .store(in: &cancellables)

        // 세션 이벤트 관찰 (체인 변경, 계정 변경)
        AppKit.instance.sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (event, sessionTopic, chainId) in
                self?.handleSessionEvent(event, sessionTopic: sessionTopic, chainId: chainId)
            }
            .store(in: &cancellables)
    }

    private func handleSessionSettled(_ session: Session) {
        print("🎯 CrossWalletManager: Handling session settled")
        print("🎯 CrossWalletManager: Session topic: \(session.topic)")
        print("🎯 CrossWalletManager: Session accounts: \(session.accounts)")
        print("🎯 CrossWalletManager: Session namespaces: \(session.namespaces.keys)")
        
        // 세션에서 첫 번째 계정과 체인 정보 추출
        guard let account = session.namespaces.values.first?.accounts.first else {
            print("❌ CrossWalletManager: No accounts found in session")
            updateConnectionState(.error(CrossSDKError.invalidSession))
            return
        }

        let address = account.address
        let chainId = account.blockchain.reference
        print("👛 CrossWalletManager: Account address: \(address)")
        print("⛓️ CrossWalletManager: Chain ID: \(chainId)")

        guard let chain = CrossChain(rawValue: chainId) else {
            print("❌ CrossWalletManager: Unsupported chain ID: \(chainId)")
            updateConnectionState(.error(CrossSDKError.unsupportedChain))
            return
        }

        let wallet = CrossWallet(address: address, chain: chain)
        print("✅ CrossWalletManager: Created wallet: \(wallet.address) on \(wallet.chain)")
        updateConnectionState(.connected(wallet))
    }

    private func handleSessionDeleted(topic: String, reason: Reason) {
        print("🔌 CrossWalletManager: Session deleted - topic: \(topic), reason: \(reason)")
        updateConnectionState(.disconnected)
    }

    private func handleSessionEvent(_ event: Session.Event, sessionTopic: String, chainId: Blockchain?) {
        switch event.name {
        case "chainChanged":
            handleChainChanged(event)
        case "accountsChanged":
            handleAccountsChanged(event)
        default:
            break
        }
    }

    private func handleChainChanged(_ event: Session.Event) {
        guard let chainReference = try? event.data.get(Int.self),
              let chain = CrossChain(rawValue: String(chainReference)) else {
            return
        }

        // 현재 연결된 지갑의 체인 업데이트
        if case .connected(let wallet) = connectionState {
            let updatedWallet = CrossWallet(address: wallet.address, chain: chain, name: wallet.name)
            updateConnectionState(.connected(updatedWallet))
            delegate?.walletChainDidChange(chain)
        }
    }

    private func handleAccountsChanged(_ event: Session.Event) {
        guard let accounts = try? event.data.get([String].self),
              let firstAccount = accounts.first else {
            return
        }

        let address = String(firstAccount.split(separator: ":").last ?? "")

        // 현재 연결된 지갑의 주소 업데이트
        if case .connected(let wallet) = connectionState {
            let updatedWallet = CrossWallet(address: address, chain: wallet.chain, name: wallet.name)
            updateConnectionState(.connected(updatedWallet))
            delegate?.walletAccountDidChange(address)
        }
    }

    private func updateConnectionState(_ newState: CrossWalletConnectionState) {
        print("🔄 CrossWalletManager: Connection state changing to: \(newState)")
        connectionState = newState
        delegate?.walletConnectionStateDidChange(newState)
    }

    /// URL 열기 (딥링크 호출)
    @MainActor
    private func openURL(_ url: URL) async {
        #if canImport(UIKit)
        if UIApplication.shared.canOpenURL(url) {
            print("✅ CrossWalletManager: Opening URL with UIApplication")
            UIApplication.shared.open(url) { success in
                if success {
                    print("✅ CrossWalletManager: Successfully opened deeplink URL")
                } else {
                    print("❌ CrossWalletManager: Failed to open deeplink URL")
                }
            }
        } else {
            print("❌ CrossWalletManager: Cannot open URL - app not installed or URL scheme not supported")
        }
        #else
        print("⚠️ CrossWalletManager: URL opening not supported on this platform")
        #endif
    }

    /// 기존 세션 확인 및 상태 복원
    private func checkAndRestoreExistingSession() {
        print("🔍 CrossWalletManager: Checking for existing sessions")
        
        // AppKit에서 활성 세션 확인
        let sessions = CrossSDKSwift.shared.getSessions()
        print("📊 CrossWalletManager: Found \(sessions.count) active sessions")
        
        if let session = sessions.first {
            print("✅ CrossWalletManager: Restoring session: \(session.topic)")
            handleSessionSettled(session)
        } else {
            print("❌ CrossWalletManager: No active sessions found")
            updateConnectionState(.disconnected)
        }
    }
}

/// CrossSDKSwift 관련 에러
public enum CrossSDKError: Error, LocalizedError {
    case invalidSession
    case unsupportedChain
    case walletNotConnected
    case invalidChain
    case requestExpired
    case invalidURL
    case receiptPollingTimeout
    case invalidReceiptData
    case rpcRequestFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSession:
            return "Invalid wallet session"
        case .unsupportedChain:
            return "Unsupported blockchain"
        case .walletNotConnected:
            return "Wallet is not connected"
        case .invalidChain:
            return "Invalid chain configuration"
        case .requestExpired:
            return "Connection request has expired"
        case .invalidURL:
            return "Invalid URL for deeplink"
        case .receiptPollingTimeout:
            return "Transaction receipt polling timeout"
        case .invalidReceiptData:
            return "Invalid transaction receipt data"
        case .rpcRequestFailed(let message):
            return "RPC request failed: \(message)"
        }
    }
}
