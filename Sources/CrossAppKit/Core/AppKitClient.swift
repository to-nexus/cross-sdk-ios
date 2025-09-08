// import class CoinbaseWalletSDK.CoinbaseWalletSDK // Temporarily removed for compatibility
// import struct CoinbaseWalletSDK.Action
// import struct CoinbaseWalletSDK.ActionError
import Combine
import Foundation
import UIKit

// Web3 Modal Client
///
/// Cannot be instantiated outside of the SDK
///
/// Access via `Web3Modal.instance`
public class AppKitClient {
    // MARK: - Public Properties
    
    /// Publisher that sends sessions on every sessions update
    ///
    /// Event will be emited on controller and non-controller clients.
    public var sessionsPublisher: AnyPublisher<[Session], Never> {
        signClient.sessionsPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends session when one is settled
    ///
    /// Event is emited on proposer and responder client when both communicating peers have successfully established a session.
    public var sessionSettlePublisher: AnyPublisher<Session, Never> {
        signClient.sessionSettlePublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends session proposal that has been rejected
    ///
    /// Event will be emited on dApp client only.
    public var sessionRejectionPublisher: AnyPublisher<(Session.Proposal, Reason), Never> {
        signClient.sessionRejectionPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends deleted session topic
    ///
    /// Event can be emited on any type of the client.
    public var sessionDeletePublisher: AnyPublisher<(String, Reason), Never> {
        signClient.sessionDeletePublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends response for session request
    ///
    /// In most cases that event will be emited on dApp client.
    public var sessionResponsePublisher: AnyPublisher<W3MResponse, Never> {
        signClient.sessionResponsePublisher
            .map { response in
                W3MResponse(
                    id: response.id,
                    topic: response.topic,
                    chainId: response.chainId,
                    result: response.result
                )
            }
            .merge(with: coinbaseResponseSubject)
            .eraseToAnyPublisher()
    }
    
    public var coinbaseResponseSubject = PassthroughSubject<W3MResponse, Never>()
    
    /// Publisher that sends web socket connection status
    public var socketConnectionStatusPublisher: AnyPublisher<SocketConnectionStatus, Never> {
        signClient.socketConnectionStatusPublisher.eraseToAnyPublisher()
    }
    
    /// Publisher that sends session event
    ///
    /// Event will be emited on dApp client only
    public var sessionEventPublisher: AnyPublisher<(event: Session.Event, sessionTopic: String, chainId: Blockchain?), Never> {
        signClient.sessionEventPublisher
            .merge(with: manualSessionEventSubject)
            .eraseToAnyPublisher()
    }

    /// Manual session event subject for triggering events programmatically
    private let manualSessionEventSubject = PassthroughSubject<(event: Session.Event, sessionTopic: String, chainId: Blockchain?), Never>()

    public var authResponsePublisher: AnyPublisher<(id: RPCID, result: Result<(Session?, [Cacao]), AuthError>), Never> {
        signClient.authResponsePublisher
    }

    public var isAnalyticsEnabled: Bool {
        return analyticsService.isAnalyticsEnabled
    }

    public var SIWEAuthenticationPublisher: AnyPublisher<Result<(message: String, signature: String), SIWEAuthenticationError>, Never> {
        return SIWEAuthenticationPublisherSubject.eraseToAnyPublisher()
    }

    internal let SIWEAuthenticationPublisherSubject = PassthroughSubject<Result<(message: String, signature: String), SIWEAuthenticationError>, Never>()

    // MARK: - Private Properties

    private let signClient: SignClient
    private let pairingClient: PairingClientProtocol & PairingInteracting & PairingRegisterer
    private let store: Store
    private let analyticsService: AnalyticsService
    private var disposeBag = Set<AnyCancellable>()
    public let logger: ConsoleLogging

    init(
        logger: ConsoleLogging,
        signClient: SignClient,
        pairingClient: PairingClientProtocol & PairingInteracting & PairingRegisterer,
        store: Store,
        analyticsService: AnalyticsService
    ) {
        self.logger = logger
        self.signClient = signClient
        self.pairingClient = pairingClient
        self.store = store
        self.analyticsService = analyticsService
        setUpConnectionEvents()
        analyticsService.track(.MODAL_LOADED)
    }
    
    /// For creating new pairing
    public func createPairing() async throws -> WalletConnectURI {
        logger.debug("Creating new pairing")
        do {
            return try await pairingClient.create()
        } catch {
            AppKit.config.onError(error)
            throw error
        }
    }
    
    /// For proposing a session to a wallet.
    /// Function will propose a session on existing pairing or create new one if not specified
    /// Namespaces from Web3Modal.config will be used
    /// - Parameters:
    ///   - topic: pairing topic
    public func connect(walletUniversalLink: String?) async throws -> WalletConnectURI? {
        logger.debug("Connecting Application")
        do {
            if let authParams = AppKit.config.authRequestParams {
                return try await signClient.authenticate(authParams, walletUniversalLink: walletUniversalLink)
            } else {
                let pairingURI = try await signClient.connect(
                    requiredNamespaces: AppKit.config.sessionParams.requiredNamespaces,
                    optionalNamespaces: AppKit.config.sessionParams.optionalNamespaces,
                    sessionProperties: AppKit.config.sessionParams.sessionProperties
                )
                return pairingURI
            }
        } catch {
            AppKit.config.onError(error)
            throw error
        }
    }
    
    /// For sending JSON-RPC requests to wallet.
    /// - Parameters:
    ///   - params: Parameters defining request and related session
    public func request(params: Request) async throws {
        do {
            try await signClient.request(params: params)
        } catch {
            AppKit.config.onError(error)
            throw error
        }
    }
    
    /// For a terminating a session
    ///
    /// Should Error:
    /// - When the session topic is not found
    /// - Parameters:
    ///   - topic: Session topic that you want to delete
    public func disconnect(topic: String) async throws {
        switch store.connectedWith {
        case .wc:
            do {
                try await signClient.disconnect(topic: topic)
                analyticsService.track(.DISCONNECT_SUCCESS)
            } catch {
                AppKit.config.onError(error)
                analyticsService.track(.DISCONNECT_ERROR)
                throw error
            }
        case .cb:
            // Coinbase functionality temporarily removed for compatibility
            break
            // if case let .failure(error) = CoinbaseWalletSDK.shared.resetSession() {
            //     analyticsService.track(.DISCONNECT_ERROR)
            //     throw error
            // } else {
                analyticsService.track(.DISCONNECT_SUCCESS)
        case .none:
            break
        }
    }
    
    /// Query sessions
    /// - Returns: All sessions
    public func getSessions() -> [Session] {
        signClient.getSessions()
    }
    
    /// Query pairings
    /// - Returns: All pairings
    public func getPairings() -> [Pairing] {
        pairingClient.getPairings()
    }
    
    /// Delete all stored data such as: pairings, sessions, keys
    ///
    /// - Note: Will unsubscribe from all topics
    public func cleanup() async throws {
        do {
            try await signClient.cleanup()
        } catch {
            AppKit.config.onError(error)
            throw error
        }
    }
    
    public func getAddress() -> String? {
        guard let account = store.account else { return nil }
        
        return account.address
    }
    
    public func getSelectedChain() -> Chain? {
        guard let chain = store.selectedChain else {
            return nil
        }
        
        return chain
    }
    
    public func addChainPreset(_ chain: Chain) {
        ChainPresets.crossWalletChains.append(chain)
    }
    
    public func selectChain(_ chain: Chain) {
        store.selectedChain = chain
    }
    
    public func launchCurrentWallet() {
        guard
            let session = store.session,
            let urlString = session.peer.redirect?.native ?? session.peer.redirect?.universal,
            let url = URL(string: urlString)
        else { return }
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url, completionHandler: nil)
        }
    }
    
    @discardableResult
    public func handleDeeplink(_ url: URL) -> Bool {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
           queryItems.contains(where: { $0.name == "wc_ev" }) {
            do {
                try signClient.dispatchEnvelope(url.absoluteString)
                return true
            } catch {
                store.toast = .init(style: .error, message: error.localizedDescription)
                return false
            }
        }
        // Coinbase functionality temporarily removed for compatibility
        return false
        // do {
        //     return try CoinbaseWalletSDK.shared.handleResponse(url)
        // } catch {
        //     store.toast = .init(style: .error, message: error.localizedDescription)
        //     return false
        // }
    }

    private func setUpConnectionEvents() {
        analyticsService.track(.MODAL_LOADED)

        signClient.sessionSettlePublisher.sink { [unowned self] session in
            self.analyticsService.track(.CONNECT_SUCCESS(method: analyticsService.method, name: session.peer.name))
        }.store(in: &disposeBag)


        signClient.sessionRejectionPublisher.sink { [unowned self] (_, reason) in
            self.analyticsService.track(.CONNECT_ERROR(message: reason.message))
        }.store(in: &disposeBag)
    }

    public func enableAnalytics() {
        analyticsService.enable()
    }

    public func disableAnalytics() {
        analyticsService.disable()
    }

    /// Manually trigger a chainChanged event
    /// - Parameter chainId: The new chain ID (e.g., "1" for Ethereum, "56" for BSC)
    /// - Note: This simulates a chainChanged event as if it came from the wallet
    public func triggerChainChangedEvent(chainId: String) {
        guard let sessions = getSessions().first else {
            logger.debug("No active session to trigger chainChanged event")
            return
        }

        guard let chainIdInt = Int(chainId) else {
            logger.debug("Invalid chainId format: \(chainId)")
            return
        }

        logger.debug("Triggering manual chainChanged event for chainId: \(chainId)")

        // Create a Session.Event for chainChanged
        let chainChangedEvent = Session.Event(
            name: "chainChanged",
            data: AnyCodable(chainIdInt)
        )

        // Create blockchain identifier
        let blockchain = Blockchain(namespace: "eip155", reference: chainId)

        // Send through manual event subject
        manualSessionEventSubject.send((
            event: chainChangedEvent,
            sessionTopic: sessions.topic,
            chainId: blockchain
        ))

        logger.debug("Manual chainChanged event triggered successfully")
    }
}
