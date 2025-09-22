# CrossSDKSwift

iOS용 Web3 DApp 개발을 위한 통합 SDK입니다. WalletConnect 프로토콜을 사용하여 지갑 연결, 체인 관리, 서명, 트랜잭션 전송 기능을 제공합니다.

## 주요 기능

- 지갑 연결 및 세션 관리
- SwiftUI `@ObservedObject` 지원
- 멀티체인 지원 (Cross, BSC, Kaia, Ethereum)
- 서명 기능 (Personal Sign, ETH Sign, EIP-712 Typed Data)
- 트랜잭션 전송 (네이티브/ERC-20)
- 잔액 조회
- 유틸리티 함수 제공

## Requirements
- iOS 13.0+
- Xcode 13.0+
- Swift 5.5+

## 지원되는 기능

### 지갑 연결
- `connectWallet()` 함수를 통한 지갑 연결
- 연결 상태 추적 (`connected`, `connecting`, `disconnected`)
- 앱 재시작 시 세션 복구
- 지갑 앱 자동 전환

### 멀티체인 지원
```swift
.crossMainnet, .crossTestnet    // Cross 네트워크
.bscMainnet, .bscTestnet        // Binance Smart Chain  
.kaiaMainnet, .kaiaTestnet      // Kaia (Klaytn)
.ethereum, .sepolia             // Ethereum
```

### 서명 기능
- Personal Sign: 텍스트 메시지 서명
- ETH Sign: 원시 바이트 데이터 서명
- EIP-712 Typed Data: 구조화된 데이터 서명
- 서명 검증 및 주소 복구

### 트랜잭션
- 네이티브 토큰 전송
- ERC-20 토큰 전송
- 동적 수수료 (EIP-1559)
- 잔액 조회
- 스마트 컨트랙트 함수 호출
- 트랜잭션 Receipt 폴링
- 자동 완료 대기 및 상태 확인

### 유틸리티
- 주소 검증 및 포맷팅
- 16진수/10진수 변환
- Wei 단위 변환
- 에러 처리

## 설치

### Swift Package Manager
Xcode에서 File → Add Package Dependencies를 선택하고 다음 URL을 입력합니다:
```
https://github.com/to-nexus/cross-sdk-swift
```

Package.swift에 직접 추가:
```swift
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-swift", from: "1.0.0")
]
```

## 초기 설정

### WalletConnect Project ID
[WalletConnect Cloud](https://cloud.walletconnect.com/)에서 프로젝트를 생성하여 Project ID를 발급받습니다.

### URL Scheme 설정
지갑 앱에서 돌아오기 위한 URL Scheme을 설정합니다.

Xcode에서 설정:
1. Target → Info → URL Types
2. "+" 버튼 클릭
3. URL Schemes: 앱 고유 스킴 (예: `mydapp`)
4. Identifier: 앱 번들 ID

Info.plist에 직접 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>mydapp</string>
        </array>
    </dict>
</array>
```

### 앱 초기화
```swift
import SwiftUI
import CrossSDKSwift

@main
struct MyApp: App {
    init() {
        CrossSDKSwift.shared.configure(
            projectId: "YOUR_PROJECT_ID",
            groupIdentifier: "group.com.yourcompany.yourapp",
            appName: "My DApp",
            appDescription: "Web3 application",
            appUrl: "https://mydapp.com",
            iconUrls: ["https://mydapp.com/icon.png"],
            redirectNative: "mydapp://",
            redirectUniversal: "https://mydapp.com/redirect",
            supportedChains: [.ethereum, .polygon, .crossMainnet]
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("Received URL: \(url)")
                }
        }
    }
}
```

## 사용법

### 1. 기본 UI 구성
```swift
import SwiftUI
import CrossSDKSwift

struct ContentView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared
    
    var body: some View {
        VStack(spacing: 20) {
            switch sdk.connectionState {
            case .connected(let wallet):
                Text("연결됨: \(sdk.utils.formatAddress(wallet.address))")
                Text("체인: \(wallet.chain.name)")
            case .connecting:
                Text("연결 중")
            case .disconnected:
                Text("연결되지 않음")
            }
            if sdk.isConnected {
                Button("지갑 연결 해제") {
                    Task { try? await sdk.disconnectWallet() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("지갑 연결") {
                    Task { try? await sdk.connectWallet() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

### 2. 지갑 연결
```swift
try await CrossSDKSwift.shared.connectWallet()
try await CrossSDKSwift.shared.switchChain(to: .ethereum)

if CrossSDKSwift.shared.isConnected {
    let wallet = CrossSDKSwift.shared.connectedWallet
    print("주소: \(wallet?.address ?? "")")
    print("체인: \(wallet?.chain.name ?? "")")
}
```

### 3. 메시지 서명
```swift
// Personal Sign
let result = try await CrossSDKSwift.shared.personalSign(
    message: "Hello, CrossSDKSwift!",
    customData: CustomData(string: "metadata")
)

// EIP-712 Typed Data
let typedData = EIP712TypedData(
    domain: EIP712Domain(name: "MyDApp", version: "1.0.0"),
    primaryType: "Message",
    types: ["Message": [EIP712Type(name: "content", type: "string")]],
    message: ["content": AnyCodable("Hello World")]
)

let result = try await CrossSDKSwift.shared.signTypedDataV4(
    typedData: typedData,
    customData: CustomData(object: ["timestamp": Date().timeIntervalSince1970])
)
```

### 4. 트랜잭션 전송

#### 기본 전송 (트랜잭션 해시만 반환)
```swift
// 네이티브 토큰 전송 - 빠른 응답
let txHash: String = try await CrossSDKSwift.shared.sendNative(
    to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
    amount: "0.01"
)
print("트랜잭션 전송됨: \(txHash)")

// 일반 트랜잭션 전송
let params = CrossTransactionParams(
    to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
    value: "0.01"
)
let txHash: String = try await CrossSDKSwift.shared.sendTransaction(params)
```

#### 완전한 전송 (Receipt까지 대기)
```swift
// 네이티브 토큰 전송 + Receipt 폴링
let receipt: CrossTransactionReceipt = try await CrossSDKSwift.shared.sendNative(
    to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
    amount: "0.01"
)

// 트랜잭션 완료 상태 확인
if receipt.receiptStatus == .success {
    print("✅ 트랜잭션 성공!")
    print("📄 블록 번호: \(receipt.blockNumber ?? "N/A")")
    print("⛽ 가스 사용량: \(receipt.gasUsed)")
    print("💰 실제 가스 비용: \(receipt.effectiveGasPrice ?? "N/A")")
} else {
    print("❌ 트랜잭션 실패")
}

// 일반 트랜잭션 + Receipt 폴링
let params = CrossTransactionParams(
    to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
    value: "0.01"
)
let receipt: CrossTransactionReceipt = try await CrossSDKSwift.shared.sendTransaction(params)

// Receipt 상세 정보 활용
print("📊 Receipt 정보:")
print("  - 상태: \(receipt.receiptStatus)")
print("  - 블록 해시: \(receipt.blockHash ?? "N/A")")
print("  - 트랜잭션 인덱스: \(receipt.transactionIndex ?? 0)")
print("  - 이벤트 로그: \(receipt.logs.count)개")

// 이벤트 로그 처리
for log in receipt.logs {
    print("📝 이벤트: \(log.address) - \(log.topics.count)개 토픽")
}
```

### 5. 잔액 조회
```swift
let nativeBalance = try await CrossSDKSwift.shared.fetchNativeBalance()
let tokenBalance = try await CrossSDKSwift.shared.fetchERC20Balance(
    contractAddress: "0xA0b86a33E6441c0c11f2f82c7A1d0D9c5d5A5A5A"
)
```

### 6. 스마트 컨트랙트

#### 컨트랙트 읽기 (view 함수)
```swift
let balanceHex = try await CrossSDKSwift.shared.transactionManager.readContract(
    contractAddress: "0xContractAddress",
    methodName: "balanceOf",
    abi: "balanceOf(address)",
    params: ["0xUserAddress"]
)
```

#### 컨트랙트 쓰기 - 기본 (해시만 반환)
```swift
// 빠른 컨트랙트 호출
let txHash: String = try await CrossSDKSwift.shared.writeContract(
    contractAddress: "0xContractAddress",
    methodName: "transfer",
    abi: "transfer(address,uint256)",
    params: ["0xRecipient", "1000000000000000000"],
    value: "0"
)
print("컨트랙트 호출됨: \(txHash)")
```

#### 컨트랙트 쓰기 - 완전한 호출 (Receipt까지 대기)
```swift
// ERC-20 토큰 전송 + Receipt 확인
let receipt: CrossTransactionReceipt = try await CrossSDKSwift.shared.writeContract(
    contractAddress: "0xTokenContract",
    methodName: "transfer",
    abi: "transfer(address,uint256)",
    params: ["0xRecipient", "1000000000000000000"],
    value: "0"
)

// 컨트랙트 호출 결과 확인
if receipt.receiptStatus == .success {
    print("✅ 토큰 전송 성공!")
    
    // Transfer 이벤트 로그 찾기
    for log in receipt.logs {
        if log.topics.count >= 3 {
            // Transfer(address indexed from, address indexed to, uint256 value)
            let from = log.topics[1]
            let to = log.topics[2] 
            print("📝 Transfer: \(from) → \(to)")
        }
    }
} else {
    print("❌ 토큰 전송 실패")
}

// NFT 민팅 예제
let mintReceipt: CrossTransactionReceipt = try await CrossSDKSwift.shared.writeContract(
    contractAddress: "0xNFTContract",
    methodName: "mint",
    abi: "mint()",
    value: "0.01" // payable 함수인 경우 ETH 전송
)

// 민팅 성공 여부 및 가스 비용 확인
print("🎨 NFT 민팅 완료!")
print("⛽ 사용된 가스: \(mintReceipt.gasUsed)")
print("💰 가스 비용: \(mintReceipt.effectiveGasPrice ?? "N/A")")
```

#### Receipt 폴링 설정 (고급)
```swift
// 커스텀 폴링 설정
let config = CrossReceiptPollingConfig(
    maxAttempts: 60,        // 최대 60번 시도
    intervalSeconds: 2.0,   // 2초 간격
    timeoutSeconds: 120.0   // 2분 타임아웃
)

let receipt = try await CrossSDKSwift.shared.transactionManager.sendTransactionAndWaitForReceipt(
    params,
    config: config
)
```

## UI 컴포넌트

### 지갑 컴포넌트
```swift
struct MyWalletView: View {
    var body: some View {
        CrossSDKWalletKit(
            showNetworkButton: true,
            showAccountInfo: true
        )
    }
}
```

### 개별 컴포넌트
```swift
CrossSDKConnectButton()
CrossSDKNetworkSelector()
SocketStatusView()
```

## 유틸리티 함수

### 주소 관련
```swift
let utils = CrossSDKSwift.shared.utils

let isValid = utils.isValidAddress("0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58")
let formatted = utils.formatAddress("0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58")
```

### 데이터 변환
```swift
let decimal = utils.hexToDecimal("0xff")
let hex = utils.decimalStringToHex("255")

let data = try utils.encodeERC20TransferData(
    to: "0xRecipient",
    amount: "100.5", 
    decimals: 18
)
```

## 예제 앱

```bash
open Example/DappSample/DappSample.xcodeproj
```

예제 화면:
- `SigningExampleView`: 서명 기능
- `SendExampleView`: 전송 기능
- `BalanceExampleView`: 잔액 조회
- `CrossSDKWalletKit`: 지갑 컴포넌트

## 고급 설정

### 커스텀 체인
```swift
extension CrossChain {
    static let myCustomChain = CrossChain(
        name: "My Chain",
        chainId: "12345",
        rpcUrl: "https://rpc.mychain.com",
        symbol: "MYC",
        decimals: 18,
        blockExplorer: "https://explorer.mychain.com"
    )
}

CrossSDKSwift.shared.configure(
    supportedChains: [.ethereum, .myCustomChain]
)
```

### 에러 처리
```swift
do {
    let result = try await CrossSDKSwift.shared.connectWallet()
} catch CrossSDKError.userRejected {
    print("사용자 거부")
} catch CrossSDKError.networkError(let message) {
    print("네트워크 오류: \(message)")
} catch {
    print("오류: \(error.localizedDescription)")
}
```

#### Receipt 폴링 에러 처리 
```swift
do {
    let receipt = try await CrossSDKSwift.shared.sendNative(
        to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
        amount: "0.01"
    )
    print("트랜잭션 완료: \(receipt.receiptStatus)")
} catch CrossSDKError.receiptPollingTimeout {
    print("⏰ Receipt 폴링 타임아웃 - 트랜잭션이 아직 마이닝되지 않았습니다")
} catch CrossSDKError.invalidReceiptData {
    print("📄 잘못된 Receipt 데이터")
} catch CrossSDKError.rpcRequestFailed(let message) {
    print("🌐 RPC 요청 실패: \(message)")
} catch {
    print("오류: \(error.localizedDescription)")
}

// Receipt 상태별 처리
if let receipt = try? await CrossSDKSwift.shared.sendNative(to: address, amount: amount) {
    switch receipt.receiptStatus {
    case .success:
        print("✅ 트랜잭션 성공!")
        // 성공 로직
    case .failure:
        print("❌ 트랜잭션 실패 - 가스 부족 또는 revert")
        // 실패 로직
    }
}
```
