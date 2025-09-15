# DappSample - 새로운 CrossSDKSwift 데모

이 프로젝트는 새로운 CrossSDKSwift API를 사용하여 CROSSx wallet 연결을 구현하는 방법을 보여주는 샘플 애플리케이션입니다.

## 🚀 새로운 CrossSDKSwift v1.0.0 사용

### ✅ 완전히 새로워진 API

이전 복잡한 설정에서 매우 간단한 API로 변경되었습니다:

#### 이전 (복잡한 빌더 패턴):
```swift
// 복잡한 빌더 패턴과 여러 설정
CrossSDKSwift.builder()
    .withProjectId(projectId)
    .withAppInfo(name: "DappSample", ...)
    .withNetworkConfig(groupIdentifier: "...")
    .withDefaultProviders()
    .build()
    .configure()
```

#### 현재 (초간단 설정):
```swift
// 단 한 줄로 모든 설정 완료!
CrossSDKSwift.shared.configure(
    projectId: "YOUR_PROJECT_ID",
    appName: "My Dapp",
    appDescription: "My awesome dapp",
    appUrl: "https://mydapp.com",
    redirectNative: "mydapp://",
    redirectUniversal: "https://mydapp.com/redirect"
)
```

## 🎯 주요 기능

1. **초간단 설정**: 한 줄 코드로 모든 설정 완료
2. **SwiftUI 완전 지원**: `@ObservedObject`로 실시간 상태 바인딩
3. **5개 주요 체인 지원**: Ethereum, Polygon, Arbitrum, Optimism, Base
4. **통합 API**: 연결, 체인 변경, 서명, 전송을 하나의 SDK로

## ⚙️ 설정 방법

### 1. URL Scheme 설정 (필수)

지갑에서 앱으로 돌아오기 위해 URL Scheme을 설정해야 합니다:

1. **Xcode에서 프로젝트 선택**
2. **Target → Info → URL Types**
3. **"+" 버튼 클릭**
4. **URL Schemes에 `dappsample` 입력** (dappsample:// 에서 :// 제외)
5. **Identifier에 `com.yourcompany.dappsample` 입력**

또는 Info.plist에 직접 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.dappsample</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>dappsample</string>
        </array>
    </dict>
</array>
```

### 2. 앱에서 URL 처리

SwiftUI에서 URL을 처리하도록 설정:
```swift
WindowGroup {
    ContentView()
        .onOpenURL { url in
            // 지갑에서 돌아왔을 때 처리
            print("Received URL: \(url)")
        }
}
```

## 🔧 새로운 API 사용법

### 지갑 연결
```swift
try await CrossSDKSwift.shared.connectWallet()
```

### 체인 변경
```swift
try await CrossSDKSwift.shared.switchChain(to: .polygon)
```

### 메시지 서명
```swift
let signature = try await CrossSDKSwift.shared.signMessage("Hello World!")
```

### ETH 전송
```swift
let txHash = try await CrossSDKSwift.shared.sendNative(to: "0x...", amount: "0.01")
```

## 📱 SwiftUI 통합

```swift
struct ContentView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared
    
    var body: some View {
        VStack {
            // 연결 상태가 자동으로 UI에 반영됨
            switch sdk.connectionState {
            case .connected(let wallet):
                Text("연결됨: \(wallet.address)")
            case .disconnected:
                Button("지갑 연결") {
                    Task { try await sdk.connectWallet() }
                }
            // ...
            }
        }
    }
}
```

## 🏗️ 프로젝트 구조

- `DappSampleApp.swift`: 새로운 CrossSDKSwift 설정
- `ContentView.swift`: 새로운 API를 사용한 메인 UI
- `CrossSDKWalletKit.swift`: 재사용 가능한 지갑 컴포넌트
- `SocketStatusView.swift`: 연결 상태 표시 컴포넌트

## 🚀 실행 방법

1. Xcode에서 프로젝트 열기:
   ```bash
   open Example/DappSample/DappSample.xcodeproj
   ```

2. 또는 Swift Package Manager로 빌드:
   ```bash
   swift build --target DappSample
   ```

## 📦 의존성

단 하나의 의존성만 필요:
- `CrossSDKSwift`: 모든 기능이 포함된 통합 SDK

## 🎓 학습 포인트

이 샘플을 통해 배울 수 있는 것들:

1. **새로운 CrossSDKSwift API**: 간단하고 직관적인 사용법
2. **SwiftUI 통합**: `@ObservedObject`를 통한 실시간 상태 관리
3. **체인 관리**: 5개 주요 체인 간 쉬운 전환
4. **트랜잭션 처리**: 서명과 전송의 간단한 구현
5. **에러 처리**: 개선된 에러 메시지와 처리 방법
