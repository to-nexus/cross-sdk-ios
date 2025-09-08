// swift-tools-version:5.5

import PackageDescription

// Determine if Yttrium should be used in debug (local) mode
let yttriumDebug = false


// Define dependencies array
var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    .package(url: "https://github.com/WalletConnect/QRCode", from: "14.3.1"),
    .package(url: "https://github.com/web3swift-team/web3swift.git", from: "3.3.1"),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.8.0"),
    // .package(name: "CoinbaseWalletSDK", url: "https://github.com/MobileWalletProtocol/wallet-mobile-sdk", .upToNextMinor(from: "1.0.0")), // Temporarily removed
//    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", .upToNextMinor(from: "1.10.0")),
]
//var yttriumTarget: Target!
//// Conditionally add Yttrium dependency
//if yttriumDebug {
//    var yttriumSwiftSettings: [SwiftSetting] = []
//    dependencies.append(.package(path: "../yttrium/crates/ffi/YttriumCore"))
//    yttriumSwiftSettings.append(.define("YTTRIUM_DEBUG"))
//    yttriumTarget = .target(
//        name: "YttriumWrapper",
//        dependencies: [.product(name: "YttriumCore", package: "YttriumCore")],
//        path: "Sources/YttriumWrapper",
//        swiftSettings: yttriumSwiftSettings
//    )
//} else {
//    dependencies.append(.package(url: "https://github.com/reown-com/yttrium", .upToNextMinor(from: "0.1.0")))
//    yttriumTarget = .target(
//        name: "YttriumWrapper",
//        dependencies: [.product(name: "Yttrium", package: "yttrium")],
//        path: "Sources/YttriumWrapper"
//    )
//}

let package = Package(
    name: "cross-sdk-swift",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "WalletConnect",
            targets: ["WalletConnectSign"]),
        .library(
            name: "WalletKit",
            targets: ["WalletKit"]),
        .library(
            name: "WalletConnectPairing",
            targets: ["WalletConnectPairing"]),
        .library(
            name: "WalletConnectNotify",
            targets: ["WalletConnectNotify"]),
        .library(
            name: "WalletConnectPush",
            targets: ["WalletConnectPush"]),
        .library(
            name: "CrossRouter",
            targets: ["CrossRouter", "WalletConnectRouterLegacy"]),
        .library(
            name: "WalletConnectNetworking",
            targets: ["WalletConnectNetworking"]),
        .library(
            name: "WalletConnectVerify",
            targets: ["WalletConnectVerify"]),
        .library(
            name: "WalletConnectIdentity",
            targets: ["WalletConnectIdentity"]),
        .library(
            name: "CrossAppKit",
            targets: ["CrossAppKit"]),
        .library(
            name: "AppKitUI",
            targets: ["AppKitUI"]),
        .library(
            name: "CrossSDKSwift",
            targets: ["CrossSDKSwift"]),
//        .library(
//            name: "YttriumWrapper",
//            targets: ["YttriumWrapper"])
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "WalletConnectSign",
            dependencies: ["WalletConnectPairing", "WalletConnectVerify", "WalletConnectSigner", "Events"],
            path: "Sources/WalletConnectSign",
            resources: [.process("Resources/PrivacyInfo.xcprivacy")]),
        .target(
            name: "WalletKit",
            dependencies: ["WalletConnectSign", "WalletConnectPush", "WalletConnectVerify"],
            path: "Sources/WalletKit",
            resources: [.process("Resources/PrivacyInfo.xcprivacy")]),
        .target(
            name: "WalletConnectNotify",
            dependencies: ["WalletConnectPairing", "WalletConnectIdentity", "WalletConnectPush", "WalletConnectSigner", "Database"],
            path: "Sources/WalletConnectNotify",
            resources: [.process("Resources/PrivacyInfo.xcprivacy")]),
        .target(
            name: "WalletConnectPush",
            dependencies: ["WalletConnectNetworking", "WalletConnectJWT"],
            path: "Sources/WalletConnectPush",
            resources: [.process("Resources/PrivacyInfo.xcprivacy")]),
        .target(
            name: "WalletConnectRelay",
            dependencies: ["WalletConnectJWT"],
            path: "Sources/WalletConnectRelay",
            resources: [.copy("PackageConfig.json"), .process("Resources/PrivacyInfo.xcprivacy")]),
        .target(
            name: "WalletConnectKMS",
            dependencies: ["WalletConnectUtils"],
            path: "Sources/WalletConnectKMS"),
        .target(
            name: "WalletConnectPairing",
            dependencies: ["WalletConnectNetworking", "Events"],
            resources: [.process("Resources/PrivacyInfo.xcprivacy")]),
        .target(
            name: "WalletConnectSigner",
            dependencies: ["WalletConnectNetworking"]),
        .target(
            name: "WalletConnectJWT",
            dependencies: ["WalletConnectKMS"]),
        .target(
            name: "WalletConnectIdentity",
            dependencies: ["WalletConnectNetworking"],
            resources: [.process("Resources/PrivacyInfo.xcprivacy")]),
        .target(
            name: "WalletConnectUtils",
            dependencies: ["JSONRPC"]),
        .target(
            name: "JSONRPC",
            dependencies: ["Commons"]),
        .target(
            name: "Commons",
            dependencies: []),
        .target(
            name: "HTTPClient",
            dependencies: []),
        .target(
            name: "WalletConnectNetworking",
            dependencies: ["HTTPClient", "WalletConnectRelay"]),
        .target(
            name: "WalletConnectRouterLegacy",
            dependencies: [],
            path: "Sources/CrossRouter/RouterLegacy"),
        .target(
            name: "CrossRouter",
            dependencies: ["WalletConnectRouterLegacy"],
            path: "Sources/CrossRouter/Router"),
        .target(
            name: "WalletConnectVerify",
            dependencies: ["WalletConnectUtils", "WalletConnectNetworking", "WalletConnectJWT"],
            resources: [.process("Resources/PrivacyInfo.xcprivacy")]),
        .target(
            name: "Database",
            dependencies: ["WalletConnectUtils"]),
        .target(
            name: "Events",
            dependencies: ["WalletConnectUtils", "WalletConnectNetworking"]),
        .target(
            name: "CrossAppKit",
            dependencies: [
                "QRCode",
                "WalletConnectSign",
                "AppKitUI",
                "AppKitBackport"
                // "CoinbaseWalletSDK" // Temporarily removed for compatibility
            ],
            path: "Sources/CrossAppKit",
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("PackageConfig.json")
            ]
        ),
        .target(
            name: "AppKitUI",
            dependencies: [
                "AppKitBackport"
            ],
            path: "Sources/AppKitUI",
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .target(
            name: "AppKitBackport",
            path: "Sources/AppKitBackport"
        ),
        .target(
            name: "CrossSDKSwift",
            dependencies: [
                "CrossAppKit", 
                "AppKitUI",
                .product(name: "web3swift", package: "web3swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift")
            ],
            path: "Sources/CrossSDKSwift"
        ),
//        yttriumTarget,
        .testTarget(
            name: "WalletConnectSignTests",
            dependencies: ["WalletConnectSign", "WalletConnectUtils", "TestingUtils", "WalletConnectVerify"]),
        .testTarget(
            name: "WalletConnectPairingTests",
            dependencies: ["WalletConnectPairing", "TestingUtils"]),
        .testTarget(
            name: "NotifyTests",
            dependencies: ["WalletConnectNotify", "TestingUtils"]),
        .testTarget(
            name: "RelayerTests",
            dependencies: ["WalletConnectRelay", "WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "VerifyTests",
            dependencies: ["WalletConnectVerify", "TestingUtils", "WalletConnectSign"]),
        .testTarget(
            name: "WalletConnectKMSTests",
            dependencies: ["WalletConnectKMS", "WalletConnectUtils", "TestingUtils"]),
        .target(
            name: "TestingUtils",
            dependencies: ["WalletConnectPairing"],
            path: "Tests/TestingUtils"),
        .testTarget(
            name: "WalletConnectUtilsTests",
            dependencies: ["WalletConnectUtils", "TestingUtils"]),
        .testTarget(
            name: "JSONRPCTests",
            dependencies: ["JSONRPC", "TestingUtils"]),
        .testTarget(
            name: "CommonsTests",
            dependencies: ["Commons", "TestingUtils"]),
        .testTarget(
            name: "EventsTests",
            dependencies: ["Events"]),
        .testTarget(
            name: "CrossSDKSwiftTests",
            dependencies: ["CrossSDKSwift", "Commons", "TestingUtils"]),
//        .testTarget(
//            name: "ReownAppKitTests",
//            dependencies: [
//                "ReownAppKit",
//                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
//            ]
//        ),
//        .testTarget(
//            name: "ReownAppKitUITests",
//            dependencies: [
//                "ReownAppKitUI",
//                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
//            ]
//        )
    ],
    swiftLanguageVersions: [.v5]
)

