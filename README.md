# CrossSDKSwift (AppKit + Dapp SDK)

Swift용 CrossSDKSwift는 AppKit과 WalletConnect를 묶어 Dapp에서 지갑 연결/서명/전송을 간단히 구현할 수 있게 하는 SDK입니다. 예제 앱(DappSample)과 함께 제공됩니다.

## Requirements
- iOS 13+
- Xcode 13+
- Swift 5

## What’s Included
- CrossSDKSwift 싱글톤 API
  - 지갑 연결/해제: `connectWallet()`, `disconnectWallet()`
  - 체인 전환: `switchChain(to:)`
  - 서명: `personalSign`, `ethSign`, `signTypedDataV4`, `signSimpleMessage`
  - 전송: `sendNative(to:amount:)`, `sendTransaction(_:)`
  - App-to-App 이동: 서명/전송 요청 후 지갑 앱 자동 전환
- 가스/수수료 처리
  - LEGACY: `gas` + `gasPrice`
  - DYNAMIC: `gas` + `maxFeePerGas` + `maxPriorityFeePerGas`
  - 가스 추정: 네트워크 RPC(Web3RPCService) → 세션 RPC 순으로 시도, 실패 시 안전한 기본값 사용
  - ETH 금액 변환: `Decimal` 기반 Wei 변환 후 0x-hex 문자열 전달
- 네임스페이스 권한
  - `eth_estimateGas`, `eth_gasPrice`, `eth_maxPriorityFeePerGas` 포함 (반영에는 재연결 필요)
- 예제 화면(DappSample)
  - 서명 예제: `SigningExampleView`
  - 전송 예제: `SendExampleView` (네이티브/ERC-20)
  - 두 화면 모두 하단 고정 버튼(safe area에서 10px 위) 및 버튼 탭 시 키보드 자동 내림

## Installation
### Swift Package Manager
프로젝트의 Swift Package에 본 저장소를 추가하세요.
```swift
dependencies: [
    .package(url: "https://github.com/your-org/cross-sdk-swift", .branch("main"))
]
```

### CocoaPods
Podfile에 다음을 추가하세요.
```ruby
pod 'cross-sdk-swift', :git => 'https://github.com/your-org/cross-sdk-swift.git', :branch => 'main'
```

## Setting Project ID
`Configuration.xcconfig`의 안내에 따라 WalletConnect Dashboard의 Project ID를 설정하세요.
```
// Uncomment next line and paste your project id. Get this on: https://cloud.walletconnect.com/sign-in
// PROJECT_ID = YOUR_PROJECT_ID
// To use Push Notifications on the Simulator you need to grab the simulator identifier
// from Window->Devices and Simulators->Simulator you're using->Identifier
SIMULATOR_IDENTIFIER = YOUR_SIMULATOR_IDENTIFIER
```

## Example App
예제 앱을 Xcode에서 실행해볼 수 있습니다.
- 열기: `Example/DappSample/DappSample.xcodeproj`
- 가이드: `Example/DappSample/JS_SCREEN_FEATURES.md`

## Documentation & References
- Xcode에서 Product → Build Documentation
- WalletConnect 문서: https://docs.walletconnect.com/2.0/swift/sign/installation
- 프로토콜 스펙: https://github.com/WalletConnect/walletconnect-specs

## License

Apache 2.0

## Guides

- [Artifacts sometimes not available in Actions -> Build name -> Artifacts?](./docs/guides/downloading_artifacts.md)
