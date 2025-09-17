# Git 태그 재설정 가이드

## 1. 기존 태그 확인 및 제거

### 현재 태그 확인
```bash
cd /Users/chuck/Documents/GitHub/cross-sdk-swift
git tag -l
```

### 로컬 태그 모두 제거
```bash
# 모든 로컬 태그 제거
git tag -l | xargs -n 1 git tag -d
```

### 원격 태그 제거 (필요시)
```bash
# 원격 태그 확인
git ls-remote --tags origin

# 원격 태그 제거 (태그 이름을 실제 태그명으로 변경)
git push origin :refs/tags/TAG_NAME

# 또는 모든 원격 태그 제거
git ls-remote --tags origin | awk '{print $2}' | sed 's|refs/tags/||' | xargs -I {} git push origin :refs/tags/{}
```

## 2. 새 태그 생성

### v1.0.0 태그 생성
```bash
git tag -a 1.0.0 -m "CrossSDKSwift v1.0.0

🚀 Features:
- Swift Package Manager 지원
- 지갑 연결 및 세션 관리  
- 멀티체인 지원 (Cross, BSC, Kaia, Ethereum)
- 서명 기능 (Personal Sign, ETH Sign, EIP-712)
- 트랜잭션 전송 및 잔액 조회
- SwiftUI @ObservedObject 지원

📦 Installation:
Swift Package Manager만 지원됩니다.

dependencies: [
    .package(url: \"https://github.com/to-nexus/cross-sdk-swift\", from: \"1.0.0\")
]

⚠️ Breaking Changes:
- CocoaPods 지원 중단
- XCFramework 지원 중단  
- Swift Package Manager 전용으로 변경"
```

### 원격 저장소에 태그 푸시
```bash
git push origin 1.0.0
```

## 3. 확인

### 태그 확인
```bash
git tag -l
git show 1.0.0
```

### 원격 태그 확인
```bash
git ls-remote --tags origin
```

## 4. GitHub Release 생성

1. GitHub 저장소로 이동
2. "Releases" → "Create a new release"
3. Tag: `1.0.0`
4. Title: `CrossSDKSwift v1.0.0`
5. Description:
```markdown
# CrossSDKSwift v1.0.0

## 🚀 주요 기능

- **Swift Package Manager 전용 지원**
- 지갑 연결 및 세션 관리
- 멀티체인 지원 (Cross, BSC, Kaia, Ethereum)
- 서명 기능 (Personal Sign, ETH Sign, EIP-712 Typed Data)
- 트랜잭션 전송 및 잔액 조회
- SwiftUI `@ObservedObject` 패턴 지원

## 📦 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-swift", from: "1.0.0")
]
```

## ⚠️ Breaking Changes

- **CocoaPods 지원 중단**: 의존성 관리 복잡성으로 인해 지원 중단
- **XCFramework 지원 중단**: 암호화 라이브러리 의존성 문제로 지원 중단
- **Swift Package Manager 전용**: 가장 안정적이고 호환성이 좋은 SPM만 지원

## 📚 문서

- [README.md](https://github.com/to-nexus/cross-sdk-swift/blob/main/README.md)
- [예제 앱](https://github.com/to-nexus/cross-sdk-swift/tree/main/Example/DappSample)

## 🐛 알려진 이슈

현재 알려진 주요 이슈는 없습니다.
```

## 5. 완료 확인

```bash
# 로컬 태그 확인
git tag -l

# 원격 태그 확인  
git ls-remote --tags origin

# 태그 상세 정보 확인
git show 1.0.0
```

---

## 실행 순서

1. 위의 명령어들을 순서대로 터미널에서 실행
2. GitHub에서 Release 생성
3. 태그가 정상적으로 생성되었는지 확인

이제 Swift Package Manager에서 `from: "1.0.0"`으로 사용할 수 있습니다!
