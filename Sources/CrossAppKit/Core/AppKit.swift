// import CoinbaseWalletSDK // Temporarily removed for compatibility
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// AppKit instance wrapper
///
/// ```Swift
/// let metadata = AppMetadata(
///     name: "Swift dapp",
///     description: "dapp",
///     url: "dapp.wallet.connect",
///     icons:  ["https://my_icon.com/1"]
/// )
/// AppKit.configure(projectId: PROJECT_ID, metadata: metadata)
/// AppKit.instance.getSessions()
/// ```
public class AppKit {
    /// AppKit client instance
    public static var instance: AppKitClient = {
        guard let config = AppKit.config else {
            fatalError("Error - you must call AppKit.configure(_:) before accessing the shared instance.")
        }
        let client = AppKitClient(
            logger: ConsoleLogger(prefix: "📜", loggingLevel: .off),
            signClient: Sign.instance,
            pairingClient: Pair.instance as! (PairingClientProtocol & PairingInteracting & PairingRegisterer),
            store: .shared,
            analyticsService: .shared
        )
        
        let store = Store.shared
        
        if let session = client.getSessions().first {
            store.session = session
            store.connectedWith = .wc
            store.account = .init(from: session)
        } else if config.coinbaseEnabled {
                  // CoinbaseWalletSDK.shared.isConnected() { // Temporarily removed

            let storedAccount = AccountStorage.read()
            store.connectedWith = .cb
            store.account = storedAccount
        } else {
            AccountStorage.clear()
        }
        
        return client
    }()
    
    struct Config {
        static let sdkVersion: String = {
            return EnvironmentInfo.sdkName                    
        }()

        static let sdkType = "appkit"
        
        let projectId: String
        var metadata: AppMetadata
        let crypto: CryptoProvider
        var sessionParams: SessionParams
        var authRequestParams: AuthRequestParams?

        let includeWebWallets: Bool
        let recommendedWalletIds: [String]
        let excludedWalletIds: [String]
        let customWallets: [Wallet]
        let coinbaseEnabled: Bool

        let onError: (Error) -> Void

    }
    
    private(set) static var config: Config!
    
    private(set) static var viewModel: Web3ModalViewModel!

    private init() {}

    /// Wallet instance wallet config method.
    /// - Parameters:
    ///   - metadata: App metadata
    public static func configure(
        projectId: String,
        metadata: AppMetadata,
        crypto: CryptoProvider,
        sessionParams: SessionParams = .default,
        authRequestParams: AuthRequestParams?,
        includeWebWallets: Bool = true,
        recommendedWalletIds: [String] = [],
        excludedWalletIds: [String] = [],
        customWallets: [Wallet] = [],
        coinbaseEnabled: Bool = true,
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        Pair.configure(metadata: metadata)
        
        AppKit.config = AppKit.Config(
            projectId: projectId,
            metadata: metadata,
            crypto: crypto,
            sessionParams: sessionParams,
            authRequestParams: authRequestParams,
            includeWebWallets: includeWebWallets,
            recommendedWalletIds: recommendedWalletIds,
            excludedWalletIds: excludedWalletIds,
            customWallets: customWallets,
            coinbaseEnabled: coinbaseEnabled,
            onError: onError
        )

        Sign.configure(crypto: crypto)

        let store = Store.shared
        let router = Router()
        let w3mApiInteractor = W3MAPIInteractor(store: store)
        let signInteractor = SignInteractor(store: store)
        let blockchainApiInteractor = BlockchainAPIInteractor(store: store)
        
        store.customWallets = customWallets
        for wallet in customWallets {
            store.walletImages[wallet.id] = UIImage(named: wallet.imageId!, in: Bundle.module, with: nil)!
        }
        
        // Load local chain images
        loadLocalChainImages(store: store)

        AppKit.viewModel = Web3ModalViewModel(
            router: router,
            store: store,
            w3mApiInteractor: w3mApiInteractor,
            signInteractor: signInteractor,
            blockchainApiInteractor: blockchainApiInteractor,
            supportsAuthenticatedSession: (config.authRequestParams != nil)
        )
        
        Task {
//            try? await w3mApiInteractor.fetchWalletImages(for: store.recentWallets + store.customWallets)
//            try? await w3mApiInteractor.fetchAllWalletMetadata()
//            try? await w3mApiInteractor.fetchFeaturedWallets()
//            try? await w3mApiInteractor.prefetchChainImages()
        }
    }
    
    public static func set(sessionParams: SessionParams) {
        AppKit.config.sessionParams = sessionParams
    }
    
    /// Load local chain images from bundle assets
    private static func loadLocalChainImages(store: Store) {
        // Define local chain images that exist in Assets.xcassets
        let localChainImages = [
            "CROSS": "CROSS",
            "BSC": "BSC",
            "KAIA": "KAIA",
            "Ethereum": "Ethereum"
        ]
        
        // Load local images for chains
        for (imageId, assetName) in localChainImages {
            if let image = UIImage(named: assetName, in: Bundle.module, with: nil) {
                store.chainImages[imageId] = image
                print("✅ AppKit: Loaded local chain image for \(imageId)")
            } else {
                print("⚠️ AppKit: Failed to load local chain image for \(imageId)")
            }
        }
    }
}

#if canImport(UIKit)

public extension AppKit {
    static func selectChain(from presentingViewController: UIViewController? = nil) {
        guard let vc = presentingViewController ?? topViewController() else {
            assertionFailure("No controller found for presenting modal")
            return
        }
        
        _ = AppKit.instance
        
        AppKit.viewModel.router.setRoute(Router.NetworkSwitchSubpage.selectChain)
        
        Store.shared.connecting = true
        
        let modal = Web3ModalSheetController(router: AppKit.viewModel.router)
        vc.present(modal, animated: true)
    }
    
    static func present(from presentingViewController: UIViewController? = nil) {
        guard let vc = presentingViewController ?? topViewController() else {
            assertionFailure("No controller found for presenting modal")
            return
        }
        
        _ = AppKit.instance
        
        Store.shared.connecting = true
        
        AppKit.viewModel.router.setRoute(Store.shared.account != nil ? Router.AccountSubpage.profile : Router.ConnectingSubpage.connectWallet)
        
        let modal = Web3ModalSheetController(router: AppKit.viewModel.router)
        vc.present(modal, animated: true)
    }
    
    private static func topViewController(_ base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .last { $0.isKeyWindow }?
            .rootViewController
        
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        
        return base
    }
}

#elseif canImport(AppKit)

import CrossAppKit

public extension AppKit {
    static func present(from presentingViewController: NSViewController? = nil) {
        let modal = Web3ModalSheetController()
        presentingViewController!.presentAsModalWindow(modal)
    }
}

#endif

public struct SessionParams {
    public let requiredNamespaces: [String: ProposalNamespace]
    public let optionalNamespaces: [String: ProposalNamespace]?
    public let sessionProperties: [String: String]?
    
    public init(requiredNamespaces: [String: ProposalNamespace], optionalNamespaces: [String: ProposalNamespace]? = nil, sessionProperties: [String: String]? = nil) {
        self.requiredNamespaces = requiredNamespaces
        self.optionalNamespaces = optionalNamespaces
        self.sessionProperties = sessionProperties
    }
    
    public static let cross: Self = {
        let methods: Set<String> = Set(EthUtils.ethMethods)
        let events: Set<String> = ["chainChanged", "accountsChanged"]
        let requiredBlockchains = ChainPresets.crossWalletChains.map(\.id).compactMap(Blockchain.init)
        let blockchains = ChainPresets.crossWalletChains.map(\.id).compactMap(Blockchain.init)

        let requiredNamespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(
                chains: requiredBlockchains,
                methods: methods,
                events: events
            ),
        ]
        let optionalNamespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(
                chains: blockchains,
                methods: methods,
                events: events
            ),
        ]

        return SessionParams(requiredNamespaces: requiredNamespaces,
                             optionalNamespaces: optionalNamespaces,
                             sessionProperties: nil)
    }()
    
    public static let `default`: Self = {
        let methods: Set<String> = Set(EthUtils.ethMethods)
        let events: Set<String> = ["chainChanged", "accountsChanged"]
        let blockchains = ChainPresets.crossChains.map(\.id).compactMap(Blockchain.init)

        let namespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(
                chains: blockchains,
                methods: methods,
                events: events
            )
        ]
        
        let optionalNamespaces: [String: ProposalNamespace] = [
            "solana": ProposalNamespace(
                chains: [
                    Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")!
                ],
                methods: [
                    "solana_signMessage",
                    "solana_signTransaction"
                ], events: []
            )
        ]
       
        return SessionParams(
            requiredNamespaces: [:],
            optionalNamespaces: namespaces.merging(optionalNamespaces, uniquingKeysWith: { old, _ in old }),
            sessionProperties: nil
        )
    }()

    /// Manually trigger a chainChanged event
    /// - Parameter chainId: The new chain ID (e.g., "1" for Ethereum, "56" for BSC)
    /// - Note: This simulates a chainChanged event as if it came from the wallet
    public static func triggerChainChangedEvent(chainId: String) {
        AppKit.instance.triggerChainChangedEvent(chainId: chainId)
    }
}
