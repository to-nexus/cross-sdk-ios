# CrossSDKSwift

CrossSDKSwift는 Dapp 개발자들이 손쉽게 CROSSx wallet을 연결하여 Dapp을 만들기 위한 SDK입니다. 기존 ReownAppKit의 복잡한 설정을 단순화하여 개발 편의성을 제공합니다.

## 주요 기능

- ✅ **간편한 지갑 연결**: 한 줄 코드로 CROSSx wallet 연결
- ✅ **체인 변경**: 지원하는 블록체인 간 쉬운 전환
- ✅ **서명 및 전송**: 메시지 서명, 트랜잭션 전송 기능
- ✅ **SwiftUI 지원**: @Published 프로퍼티로 UI 바인딩 지원

## 지원 체인

- Ethereum (ETH)
- Polygon (MATIC)
- Arbitrum One (ETH)
- Optimism (ETH)
- Base (ETH)

## 설치

Package.swift에 다음을 추가하세요:

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/reown-swift", from: "1.0.0")
]
```

## 사용법

### 1. 초기 설정

```swift
import CrossSDKSwift

// AppDelegate 또는 App 초기화 시
CrossSDKSwift.shared.configure(
    projectId: "YOUR_WALLETCONNECT_PROJECT_ID",
    appName: "My Dapp",
    appDescription: "My awesome dapp",
    appUrl: "https://mydapp.com",
    iconUrls: ["https://mydapp.com/icon.png"]
)
```

### 2. 지갑 연결

```swift
// 지갑 연결
try await CrossSDKSwift.shared.connectWallet()

// 연결 상태 확인
if CrossSDKSwift.shared.isConnected {
    print("지갑이 연결되었습니다!")
    print("주소: \(CrossSDKSwift.shared.connectedWallet?.address ?? "")")
}
```

### 3. 체인 변경

```swift
// Polygon으로 체인 변경
try await CrossSDKSwift.shared.switchChain(to: .polygon)

// 현재 체인 확인
if let currentChain = CrossSDKSwift.shared.currentChain {
    print("현재 체인: \(currentChain.name)")
}
```

### 4. 메시지 서명

```swift
let message = "Hello, CrossSDKSwift!"
let signature = try await CrossSDKSwift.shared.signMessage(message)
print("서명: \(signature)")
```

### 5. 트랜잭션 전송

```swift
// 네이티브 전송
let txHash = try await CrossSDKSwift.shared.sendNative(
    to: "0x742d35Cc6634C0532925a3b8D2C0b5C6C8b9c3f7",
    amount: "0.01"
)
print("트랜잭션 해시: \(txHash)")

// 커스텀 트랜잭션
let params = CrossTransactionParams(
    to: "0x742d35Cc6634C0532925a3b8D2C0b5C6C8b9c3f7",
    value: "0.01",
    data: "0x",
    gasLimit: "21000"
)
let txHash = try await CrossSDKSwift.shared.sendTransaction(params)
```

### 6. SwiftUI에서 사용

```swift
import SwiftUI
import CrossSDKSwift

struct ContentView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared
    
    var body: some View {
        VStack {
            switch sdk.connectionState {
            case .disconnected:
                Button("지갑 연결") {
                    Task {
                        try await sdk.connectWallet()
                    }
                }
            case .connecting:
                ProgressView("연결 중...")
            case .connected(let wallet):
                VStack {
                    Text("연결됨: \(wallet.address)")
                    Text("체인: \(wallet.chain.name)")
                    
                    Button("Polygon으로 변경") {
                        Task {
                            try await sdk.switchChain(to: .polygon)
                        }
                    }
                    
                    Button("연결 해제") {
                        Task {
                            try await sdk.disconnectWallet()
                        }
                    }
                }
            case .error(let error):
                Text("에러: \(error.localizedDescription)")
            }
        }
    }
}
```

## 에러 처리

```swift
do {
    try await CrossSDKSwift.shared.connectWallet()
} catch CrossSDKError.walletNotConnected {
    print("지갑이 연결되지 않았습니다")
} catch CrossSDKError.unsupportedChain {
    print("지원하지 않는 체인입니다")
} catch {
    print("에러 발생: \(error)")
}
```

## 라이센스

MIT License
