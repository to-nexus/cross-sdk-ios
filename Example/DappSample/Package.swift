// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "DappSample",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    dependencies: [
        // 로컬 패키지 참조 (상위 디렉토리의 reown-swift 패키지)
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "DappSample",
            dependencies: [
                // 새로운 CrossSDKSwift 패키지 사용
                .product(name: "CrossSDKSwift", package: "reown-swift-1-1-1")
            ],
            path: "DappSample",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
