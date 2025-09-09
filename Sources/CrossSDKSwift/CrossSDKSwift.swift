import Foundation
import CrossAppKit
import AppKitUI
import WalletConnectSign
import WalletConnectUtils
import Combine

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import CrossAppKit
#endif

/// CrossSDKSwift provides cross-platform SDK functionality with AppKit integration
/// Simplifies Dapp development by providing easy-to-use APIs for wallet connection,
/// chain switching, and transaction signing/sending.
public final class CrossSDKSwift: ObservableObject {

    /// SDK version
    public static let version = "1.0.0"

    /// Shared instance of CrossSDKSwift
    public static let shared = CrossSDKSwift()

    // MARK: - Managers

    /// Wallet connection manager
    public let walletManager = CrossWalletManager()

    /// Chain management
    public let chainManager = CrossChainManager()

    /// Transaction and signing manager
    public let transactionManager = CrossTransactionManager()

    /// Advanced signing manager for different signature types
    public let signingManager = CrossSigningManager()

    /// Utility functions for data conversion and formatting
    public let utils = CrossUtils()

    // MARK: - Published Properties

    /// Current wallet connection state (기존)
    @Published public var connectionState: CrossWalletConnectionState = .disconnected

    /// Current selected chain
    @Published public var currentChain: CrossChain?

    // MARK: - 새로운 상세 상태 관리

    /// 상세한 연결 상태
    @Published public var detailedConnectionState: CrossConnectionState = .idle

    /// 실시간 연결 이벤트 스트림
    @Published public var lastEvent: CrossConnectionEvent?

    // MARK: - Computed Properties

    /// Currently connected wallet
    public var connectedWallet: CrossWallet? {
        return walletManager.connectedWallet
    }

    /// Whether a wallet is connected
    public var isConnected: Bool {
        return walletManager.isConnected
    }

    /// All supported chains
    public var supportedChains: [CrossChain] {
        return chainManager.supportedChains
    }

    // MARK: - 이벤트 Publisher들

    /// 연결 이벤트 스트림 (Combine)
    public let connectionEventPublisher = PassthroughSubject<CrossConnectionEvent, Never>()

    /// 상태 변경 스트림
    public let stateChangePublisher = PassthroughSubject<CrossConnectionState, Never>()

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupBindings()
        setupAppLifecycleObservers()
    }

    // MARK: - Configuration

        /// Initialize CrossSDKSwift with simplified configuration for CROSSx wallet
    /// - Parameters:
    ///   - projectId: WalletConnect project ID
    ///   - appName: Your app name
    ///   - appDescription: Your app description
    ///   - appUrl: Your app URL
    ///   - iconUrls: Array of icon URLs
    ///   - redirectNative: Native redirect URL scheme (e.g., "dappsample://")
    ///   - redirectUniversal: Universal link for redirect (optional)
    ///   - supportedChains: Chains to support (default: all available)
    public func configure(
        projectId: String,
        groupIdentifier: String,
        appName: String,
        appDescription: String,
        appUrl: String,
        iconUrls: [String] = [],
        redirectNative: String = "",
        redirectUniversal: String = "",
        supportedChains: [CrossChain] = CrossChain.allCases
    ) {
        let metadata = createAppMetadata(
            name: appName,
            description: appDescription,
            url: appUrl,
            icons: iconUrls,
            redirectNative: redirectNative,
            redirectUniversal: redirectUniversal
        )

        let chains = createChainConfigurations(for: supportedChains)
        let sessionParams = createSessionParams(for: chains)

        configureNetwork(groupIdentifier: groupIdentifier, projectId: projectId)

        configureAppKit(
            projectId: projectId,
            metadata: metadata,
            sessionParams: sessionParams
        )

        setupEventObservers()

        signingManager.configure()
    }

    // MARK: - Wallet Connection

    /// Connect to CROSSx wallet
    public func connectWallet() async throws {
        try await walletManager.connectWallet()
    }

    public func appKitPresent() {
        AppKit.present()
    }
    /// Disconnect from wallet
    public func disconnectWallet() async throws {
        try await walletManager.disconnectWallet()
    }

    // MARK: - Chain Management

    /// Switch to a different blockchain (requires wallet approval)
    /// - Parameter chain: Target chain to switch to
    public func switchChain(to chain: CrossChain) {
        chainManager.switchChainImmediately(to: chain)
    }

    // MARK: - Transaction

    /// Send a transaction
    /// - Parameter params: Transaction parameters
    /// - Returns: Transaction hash
    public func sendTransaction(_ params: CrossTransactionParams, customData: CustomData? = nil) async throws -> String {
        return try await transactionManager.sendTransaction(params, customData: customData)
    }

    // MARK: - Advanced Signing Methods

    /// Personal Sign - 사용자가 읽을 수 있는 메시지에 서명
    /// - Parameters:
    ///   - message: 서명할 메시지
    ///   - account: 서명할 계정 주소 (optional, 현재 연결된 계정 사용)
    /// - Returns: 서명 결과
    public func personalSign(message: String, account: String? = nil, customData: CustomData? = nil) async throws -> CrossSigningResult {
        let signingAccount = account ?? connectedWallet?.address ?? ""
        guard !signingAccount.isEmpty else {
            throw CrossSigningError.noActiveSession
        }
        return try await signingManager.personalSign(message: message, account: signingAccount, customData: customData)
    }

    /// ETH Sign - 원시 바이트 데이터에 서명 (위험할 수 있음)
    /// - Parameters:
    ///   - data: 서명할 32바이트 데이터
    ///   - account: 서명할 계정 주소 (optional, 현재 연결된 계정 사용)
    /// - Returns: 서명 결과
    public func ethSign(data: Data, account: String? = nil, customData: CustomData? = nil) async throws -> CrossSigningResult {
        let signingAccount = account ?? connectedWallet?.address ?? ""
        guard !signingAccount.isEmpty else {
            throw CrossSigningError.noActiveSession
        }
        return try await signingManager.ethSign(data: data, account: signingAccount, customData: customData)
    }

    /// EIP-712 Typed Data V4 서명 - 구조화된 데이터에 서명
    /// - Parameters:
    ///   - typedData: EIP-712 구조화된 데이터
    ///   - account: 서명할 계정 주소 (optional, 현재 연결된 계정 사용)
    /// - Returns: 서명 결과
    public func signTypedDataV4(typedData: EIP712TypedData, account: String? = nil, customData: CustomData? = nil) async throws -> CrossSigningResult {
        let signingAccount = account ?? connectedWallet?.address ?? ""
        guard !signingAccount.isEmpty else {
            throw CrossSigningError.noActiveSession
        }
        return try await signingManager.signTypedDataV4(typedData: typedData, account: signingAccount, customData: customData)
    }

    /// 간단한 EIP-712 메시지 서명 - 편의 메서드
    /// - Parameters:
    ///   - message: 서명할 메시지
    ///   - account: 서명할 계정 주소 (optional, 현재 연결된 계정 사용)
    ///   - domain: 도메인 정보 (optional, 기본값 사용)
    /// - Returns: 서명 결과
    public func signSimpleMessage(message: String, account: String? = nil, domain: EIP712Domain? = nil, customData: CustomData? = nil) async throws -> CrossSigningResult {
        let signingAccount = account ?? connectedWallet?.address ?? ""
        guard !signingAccount.isEmpty else {
            throw CrossSigningError.noActiveSession
        }
        return try await signingManager.signSimpleMessage(message: message, account: signingAccount, domain: domain, customData: customData)
    }

    // MARK: - Convenience Methods

    /// Send native coin to an address
    /// - Parameters:
    ///   - to: Recipient address
    ///   - amount: Amount in native coin units (e.g., ETH)
    ///   - customData: Optional custom metadata to include with the request
    /// - Returns: Transaction hash
    public func sendNative(to address: String, amount: String, customData: CustomData? = nil) async throws -> String {
        let params = CrossTransactionParams(to: address, value: amount)
        return try await sendTransaction(params, customData: customData)
    }

    @available(*, deprecated, renamed: "sendNative(to:amount:)")
    public func sendETH(to address: String, amount: String) async throws -> String {
        return try await sendNative(to: address, amount: amount)
    }
    
    // MARK: - Balance Query Methods
    
    /// 현재 연결된 지갑의 Native 토큰 잔액 조회
    /// - Parameter address: 조회할 주소 (optional, 현재 연결된 지갑 주소 사용)
    /// - Returns: Wei 단위의 잔액 문자열
    public func fetchNativeBalance(address: String? = nil) async throws -> String {
        let queryAddress = address ?? connectedWallet?.address
        guard let queryAddress = queryAddress else {
            throw CrossSDKError.walletNotConnected
        }
        
        guard let rpcUrl = currentChain?.rpcUrl else {
            throw CrossSDKError.invalidChain
        }
        
        let balanceHex = try await transactionManager.performDirectRPCCall(
            rpcUrl: rpcUrl,
            method: "eth_getBalance",
            params: [queryAddress, "latest"]
        )
        
        let balanceWei = utils.hexToDecimal(balanceHex)
        return NSDecimalNumber(decimal: balanceWei).stringValue
    }
    
    /// ERC-20 토큰 잔액 조회
    /// - Parameters:
    ///   - contractAddress: ERC-20 토큰 컨트랙트 주소
    ///   - address: 조회할 주소 (optional, 현재 연결된 지갑 주소 사용)
    /// - Returns: 토큰의 최소 단위 잔액 문자열
    public func fetchERC20Balance(contractAddress: String, address: String? = nil) async throws -> String {
        let queryAddress = address ?? connectedWallet?.address
        guard let queryAddress = queryAddress else {
            throw CrossSDKError.walletNotConnected
        }
        
        let balanceHex = try await transactionManager.readContract(
            contractAddress: contractAddress,
            methodName: "balanceOf",
            abi: "balanceOf(address)",
            params: [queryAddress]
        )
        
        let balanceDecimal = utils.hexToDecimal(balanceHex)
        return NSDecimalNumber(decimal: balanceDecimal).stringValue
    }
    
    /// Native 토큰 잔액을 포맷된 형태로 조회
    /// - Parameter address: 조회할 주소 (optional, 현재 연결된 지갑 주소 사용)
    /// - Returns: 사용자가 읽기 쉬운 형태의 잔액 (예: "1.234567")
    public func fetchFormattedNativeBalance(address: String? = nil) async throws -> String {
        let balanceWei = try await fetchNativeBalance(address: address)
        return formatBalance(balanceWei, decimals: currentChain?.decimals ?? 18)
    }
    
    /// ERC-20 토큰 잔액을 포맷된 형태로 조회
    /// - Parameters:
    ///   - contractAddress: ERC-20 토큰 컨트랙트 주소
    ///   - decimals: 토큰의 소수점 자릿수
    ///   - address: 조회할 주소 (optional, 현재 연결된 지갑 주소 사용)
    /// - Returns: 사용자가 읽기 쉬운 형태의 잔액
    public func fetchFormattedERC20Balance(contractAddress: String, decimals: Int = 18, address: String? = nil) async throws -> String {
        let balanceRaw = try await fetchERC20Balance(contractAddress: contractAddress, address: address)
        return formatBalance(balanceRaw, decimals: decimals)
    }
    
    /// 잔액을 포맷된 형태로 변환하는 헬퍼 메소드
    /// - Parameters:
    ///   - balance: 최소 단위 잔액 문자열
    ///   - decimals: 소수점 자릿수
    /// - Returns: 포맷된 잔액 문자열
    private func formatBalance(_ balance: String, decimals: Int) -> String {
        guard let balanceDecimal = Decimal(string: balance) else { return "0" }
        
        let divisor = pow(Decimal(10), decimals)
        let formatted = balanceDecimal / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        
        return formatter.string(from: NSDecimalNumber(decimal: formatted)) ?? "0"
    }

    // MARK: - 새로운 상태 관리 메서드

        // MARK: - Private Methods

    private func setupBindings() {
        // Bind wallet manager state to published properties
        walletManager.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)

        // Bind chain manager state to published properties
        chainManager.$currentChain
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentChain, on: self)
            .store(in: &cancellables)
    }

    private func createAppMetadata(
        name: String,
        description: String,
        url: String,
        icons: [String],
        redirectNative: String,
        redirectUniversal: String
    ) -> AppMetadata {
        let redirect: AppMetadata.Redirect = try! .init(
            native: redirectNative.isEmpty ? "" : redirectNative,
            universal: redirectUniversal.isEmpty ? nil : redirectUniversal,
            linkMode: false
        )
        return AppMetadata(
            name: name,
            description: description,
            url: url,
            icons: icons,
            redirect: redirect
        )
    }

    private func createChainConfigurations(for supportedChains: [CrossChain]) -> [Chain] {
        return supportedChains.compactMap { crossChain in
            // ChainPresets에서 직접 체인 정보를 가져와서 사용
            return ChainPresets.crossWalletChains.first { $0.chainReference == crossChain.rawValue }
        }
    }

    private func createSessionParams(for chains: [Chain]) -> SessionParams {
        return .cross
    }

    private func configureNetwork(groupIdentifier: String, projectId: String) {
        Networking.configure(
            groupIdentifier: groupIdentifier,
            projectId: projectId,
            socketFactory: DefaultSocketFactory(),
            socketConnectionType: .automatic
        )
    }

    private func configureAppKit(projectId: String, metadata: AppMetadata, sessionParams: SessionParams) {
        let CrossWallet = Wallet.CROSSx
        AppKit.configure(
            projectId: projectId,
            metadata: metadata,
            crypto: DefaultCryptoProvider(),
            sessionParams: sessionParams,
            authRequestParams: nil,
            includeWebWallets: true,
            recommendedWalletIds: [],
            excludedWalletIds: [],
            customWallets: [CrossWallet],
            coinbaseEnabled: false
        ) { error in
            print("CrossSDKSwift configuration error: \(error)")
        }

        // AppKit 설정 완료 후 managers 초기화
        setupManagersAfterConfiguration()
    }

    private func setupManagersAfterConfiguration() {
        print("🔧 CrossSDKSwift: Setting up managers after AppKit configuration")
        walletManager.setupAfterAppKitConfiguration()
        chainManager.setupAfterAppKitConfiguration()
        transactionManager.setupAfterAppKitConfiguration()
        print("✅ CrossSDKSwift: All managers setup completed")
    }

    // MARK: - 새로운 이벤트 관리 메서드들

    private func setupEventObservers() {
        print("🔧 CrossSDKSwift: Setting up event observers")

        // CrossWalletManager의 연결 상태 변화를 관찰
        walletManager.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionState in
                print("📱 CrossSDKSwift: WalletManager state changed to: \(connectionState)")
                self?.handleWalletConnectionStateChange(connectionState)
            }
            .store(in: &cancellables)

        // AppKit의 이벤트들을 직접 관찰 (CrossWalletManager와 동일한 소스 사용)
        AppKit.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                print("🎯 CrossSDKSwift: AppKit sessionSettled received")
                print("🎯 CrossSDKSwift: Session topic: \(session.topic)")
                print("🎯 CrossSDKSwift: Session accounts: \(session.accounts)")
                self?.handleSessionSettled(session)
            }
            .store(in: &cancellables)

        // Sign.instance도 직접 관찰 (추가 디버깅)
        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                print("🎉 CrossSDKSwift: Sign.instance session settled: \(session.topic)")
                print("🎉 CrossSDKSwift: Session accounts: \(session.accounts)")
                print("🎉 CrossSDKSwift: Session peer: \(session.peer.name)")
                self?.handleSessionSettled(session)
            }
            .store(in: &cancellables)

        AppKit.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (topic, reason) in
                print("🔴 CrossSDKSwift: AppKit sessionDeleted received")
                self?.handleSessionDeleted(reason: reason.message)
            }
            .store(in: &cancellables)

        // Sign의 인증 관련 이벤트들
        Sign.instance.authResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleAuthResponse(response.result)
            }
            .store(in: &cancellables)

        Sign.instance.requestExpirationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRequestExpired()
            }
            .store(in: &cancellables)

        // 세션 업데이트 감지 (디버깅용)
        Sign.instance.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                print("📊 CrossSDKSwift: Sessions updated, count: \(sessions.count)")
                if let session = sessions.first {
                    print("📊 CrossSDKSwift: First session topic: \(session.topic)")
                    print("📊 CrossSDKSwift: First session accounts: \(session.accounts)")
                }
            }
            .store(in: &cancellables)

        // 세션 응답 이벤트 관찰 (디버깅용)
        Sign.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                print("📨 CrossSDKSwift: Session response received")
                print("📨 CrossSDKSwift: Response topic: \(response.topic)")
                print("📨 CrossSDKSwift: Response result: \(response.result)")
            }
            .store(in: &cancellables)

        // 소켓 연결 상태 관찰 (디버깅용)
        Sign.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                print("🔌 CrossSDKSwift: Socket connection status: \(status)")
            }
            .store(in: &cancellables)

        // 세션 제안 응답 관찰 (디버깅용)
        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (proposal, context) in
                print("📋 CrossSDKSwift: Session proposal received")
                print("📋 CrossSDKSwift: Proposal ID: \(proposal.id)")
                print("📋 CrossSDKSwift: Proposer: \(proposal.proposer.name)")
            }
            .store(in: &cancellables)

        // 세션 거부 이벤트 관찰 (디버깅용)
        Sign.instance.sessionRejectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (proposal, reason) in
                print("❌ CrossSDKSwift: Session rejected")
                print("❌ CrossSDKSwift: Proposal ID: \(proposal.id)")
                print("❌ CrossSDKSwift: Reason: \(reason.message)")
            }
            .store(in: &cancellables)
    }

    private func handleWalletConnectionStateChange(_ connectionState: CrossWalletConnectionState) {
        print("🔄 CrossSDKSwift: Handling wallet connection state change: \(connectionState)")

        // CrossWalletManager의 상태를 CrossConnectionState로 변환
        switch connectionState {
        case .disconnected:
            print("❌ CrossSDKSwift: Setting state to disconnected")
            updateDetailedConnectionState(.disconnected)
            publishEvent(.sessionDeleted("User disconnected"))
        case .connecting:
            print("🟡 CrossSDKSwift: Setting state to connecting")
            updateDetailedConnectionState(.connecting)
        case .connected(let wallet):
            print("✅ CrossSDKSwift: Setting state to connected with wallet: \(wallet.address)")
            updateDetailedConnectionState(.connected(wallet))
            publishEvent(.sessionSettled(wallet))
        case .error(let error):
            print("🔴 CrossSDKSwift: Setting state to error: \(error)")
            updateDetailedConnectionState(.error(error))
            publishEvent(.authenticationFailed(error))
        }
    }

    private func handleSessionSettled(_ session: Session) {
        // 기존 로직 + 이벤트 발행
        guard let wallet = createWalletFromSession(session) else {
            let error = CrossSDKError.invalidSession
            updateDetailedConnectionState(.error(error))
            publishEvent(.authenticationFailed(error))
            return
        }

        updateDetailedConnectionState(.connected(wallet))
        publishEvent(.sessionSettled(wallet))
    }

    private func handleSessionDeleted(reason: String) {
        updateDetailedConnectionState(.disconnected)
        publishEvent(.sessionDeleted(reason))
    }

    private func handleAuthResponse(_ result: Any) {
        // Mirror를 사용해서 Result 타입을 안전하게 처리
        let mirror = Mirror(reflecting: result)

        // Result의 success case 확인
        if let successCase = mirror.children.first(where: { $0.label == "success" }) {
            if let tuple = successCase.value as? (Session?, Any) {
                if let session = tuple.0 {
                    handleSessionSettled(session)
                } else {
                    publishEvent(.authenticationSuccess)
                }
            }
        } else {
            // failure case
            let error = CrossSDKError.invalidSession
            updateDetailedConnectionState(.error(error))
            publishEvent(.authenticationFailed(error))
        }
    }

    private func handleRequestExpired() {
        let error = CrossSDKError.requestExpired
        updateDetailedConnectionState(.error(error))
        publishEvent(.requestExpired)
    }

    private func updateDetailedConnectionState(_ newState: CrossConnectionState) {
        print("🔄 CrossSDKSwift: Updating detailed connection state to: \(newState)")
        detailedConnectionState = newState
        stateChangePublisher.send(newState)
    }

    private func publishEvent(_ event: CrossConnectionEvent) {
        print("📡 CrossSDKSwift: Publishing event: \(event)")
        lastEvent = event
        connectionEventPublisher.send(event)
    }

    private func createWalletFromSession(_ session: Session) -> CrossWallet? {
        guard let account = session.namespaces.values.first?.accounts.first else {
            return nil
        }

        let address = account.address
        let chainId = account.blockchain.reference

        guard let chain = CrossChain(rawValue: chainId) else {
            return nil
        }

        return CrossWallet(address: address, chain: chain)
    }

    // MARK: - 앱 라이프사이클 관리

    private func setupAppLifecycleObservers() {
        print("🔧 CrossSDKSwift: Setting up app lifecycle observers")

        #if canImport(UIKit)
        // iOS/tvOS 앱 라이프사이클 관찰
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidBecomeActive()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }

        #elseif canImport(AppKit)
        // macOS 앱 라이프사이클 관찰
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidWake()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillSleep()
        }
        #endif
    }

    // MARK: - 앱 라이프사이클 이벤트 핸들러

    private func handleAppWillEnterForeground() {
        print("🌅 CrossSDKSwift: App will enter foreground")

        // 포그라운드로 올라올 때 세션 상태 확인
        checkAndRestoreSessionState()

        // 연결 상태 재확인
        refreshConnectionState()
    }

    private func handleAppDidBecomeActive() {
        print("✨ CrossSDKSwift: App did become active")

        // 앱이 활성화될 때 추가 처리
        validateCurrentSession()
    }

    private func handleAppDidEnterBackground() {
        print("🌙 CrossSDKSwift: App did enter background")

        // 백그라운드로 갈 때 필요한 정리 작업
    }

    private func handleAppDidWake() {
        print("🌅 CrossSDKSwift: Mac did wake from sleep")

        // macOS에서 슬립에서 깨어날 때
        checkAndRestoreSessionState()
        refreshConnectionState()
    }

    private func handleAppWillSleep() {
        print("😴 CrossSDKSwift: Mac will sleep")

        // macOS에서 슬립 모드로 들어갈 때
    }

    // MARK: - 세션 상태 관리 헬퍼 메서드들

    private func checkAndRestoreSessionState() {
        print("🔍 CrossSDKSwift: Checking and restoring session state")

        // AppKit과 Sign 인스턴스 모두에서 세션 확인
        let appKitSessions = getSessions()
        let signSessions = Sign.instance.getSessions()

        print("📊 CrossSDKSwift: AppKit sessions: \(appKitSessions.count)")
        print("📊 CrossSDKSwift: Sign sessions: \(signSessions.count)")

        // Sign 인스턴스에서 세션 찾기 (더 최신 상태일 가능성)
        if let session = signSessions.first {
            print("✅ CrossSDKSwift: Restoring session from Sign instance: \(session.topic)")

            // 세션에서 지갑 정보 추출
            if let wallet = createWalletFromSession(session) {
                print("👛 CrossSDKSwift: Restored wallet: \(wallet.address)")
                updateDetailedConnectionState(.connected(wallet))
                publishEvent(.sessionSettled(wallet))
                return
            }
        }

        // AppKit에서 세션 찾기
        if let session = appKitSessions.first {
            print("✅ CrossSDKSwift: Restoring session from AppKit: \(session.topic)")

            // 세션에서 지갑 정보 추출
            if let wallet = createWalletFromSession(session) {
                print("👛 CrossSDKSwift: Restored wallet: \(wallet.address)")
                updateDetailedConnectionState(.connected(wallet))
                publishEvent(.sessionSettled(wallet))
                return
            }
        }

        print("❌ CrossSDKSwift: No sessions found, setting to disconnected")
        updateDetailedConnectionState(.disconnected)
    }

    private func refreshConnectionState() {
        print("🔄 CrossSDKSwift: Refreshing connection state")

        // WalletManager의 현재 상태와 동기화
        let currentState = walletManager.connectionState
        print("📱 CrossSDKSwift: Current WalletManager state: \(currentState)")

        handleWalletConnectionStateChange(currentState)
    }

    private func validateCurrentSession() {
        print("✅ CrossSDKSwift: Validating current session")

        // 현재 연결 상태가 실제 세션과 일치하는지 확인
        let sessions = getSessions()
        let hasValidSession = !sessions.isEmpty

        switch detailedConnectionState {
        case .connected:
            if !hasValidSession {
                print("⚠️ CrossSDKSwift: Connected state but no valid session found")
                updateDetailedConnectionState(.disconnected)
                publishEvent(.sessionDeleted("Session validation failed"))
            }
        case .disconnected:
            if hasValidSession {
                print("⚠️ CrossSDKSwift: Disconnected state but valid session exists")
                checkAndRestoreSessionState()
            }
        default:
            break
        }
    }

    // MARK: - 수동 세션 상태 새로고침 (디버깅용)

    public func forceRefreshSessionState() {
        print("🔄 CrossSDKSwift: Force refreshing session state...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkAndRestoreSessionState()
            self.refreshConnectionState()
        }
    }

    // MARK: - Session Management

    /// Get all active sessions
    /// - Returns: Array of active WalletConnect sessions
    public func getSessions() -> [Session] {
        return AppKit.instance.getSessions()
    }

    /// Get the current active session (first session if multiple exist)
    /// - Returns: Current active session or nil if no session exists
    public func getCurrentSession() -> Session? {
        return AppKit.instance.getSessions().first
    }

    /// Check if there are any active sessions
    /// - Returns: True if at least one session exists
    public func hasActiveSession() -> Bool {
        return !AppKit.instance.getSessions().isEmpty
    }

    /// Get session count
    /// - Returns: Number of active sessions
    public func getSessionCount() -> Int {
        return AppKit.instance.getSessions().count
    }

    deinit {
        // NotificationCenter observer 정리는 ARC가 자동으로 처리
        print("🗑️ CrossSDKSwift: Deinitializing")
    }
}
