# Changelog

## [2025-01-27] - 예제 프로젝트 정리 및 Git 저장소 초기화

### 🗂️ 예제 프로젝트 구조 개선
DappSample을 제외한 불필요한 예제 프로젝트들을 제거하여 프로젝트 구조를 단순화했습니다.

### 🗑️ 제거된 예제들
- `Example/AppKitLab/` - AppKit 테스트용 예제
- `Example/DApp/` - 기본 DApp 예제  
- `Example/ExampleApp/` - 일반 예제 앱
- `Example/WalletApp/` - 지갑 앱 예제
- 기타 테스트 관련 디렉토리들

### 📦 유지된 예제
- `Example/DappSample/` - 메인 DApp 샘플 (README.md 포함)

### ✅ 개선 효과
- 프로젝트 구조 단순화
- 유지보수 부담 감소
- 개발자들이 핵심 예제에 집중할 수 있도록 개선
- 저장소 크기 최적화

### 🔄 Git 저장소 초기화
기존 Reown 저장소와의 연결을 완전히 제거하고 새로운 독립적인 저장소로 초기화했습니다.

### 🔧 수행된 작업
- 기존 `.git` 디렉토리 완전 제거
- 새로운 Git 저장소 초기화 (`git init`)
- 원격 저장소 연결 해제 (이전: `origin  https://github.com/reown-com/reown-swift.git`)

### 📋 현재 상태
- ✅ 새로운 독립적인 Git 저장소 생성 완료
- ✅ 기존 커밋 히스토리 완전 제거
- ✅ 새로운 레포 배포 준비 완료

### 🔧 DappSample 빌드 오류 해결
프로젝트 설정과 코드 오류를 수정하여 성공적으로 빌드되도록 개선했습니다.

### 🛠️ 해결된 문제들
1. **패키지 의존성 오류**: 프로젝트에서 `CrossAppKit` 대신 `CrossSDKSwift`를 올바르게 참조하도록 수정
2. **Info.plist 중복 오류**: 수동 Info.plist 파일 제거하고 자동 생성 설정 사용
3. **Import 오류**: `CrossAppKit` import 추가
4. **API 참조 오류**: `CrossAppKit.instance` → `AppKit.instance`로 수정

### ✅ 최종 결과
- 🎉 **DappSample 프로젝트 빌드 성공**
- 📱 iPhone 시뮬레이터에서 실행 가능
- 🔗 CrossSDKSwift 패키지 정상 연동

### 🚀 GitHub 저장소 배포 완료
CrossSDKSwift 프로젝트가 새로운 독립 저장소에 성공적으로 배포되었습니다.

### 📋 배포 정보
- **저장소**: https://github.com/to-nexus/cross-sdk-swift
- **브랜치**: main
- **커밋 메시지**: `crs-2852: Initial commit - CrossSDKSwift 독립 저장소`
- **파일 수**: 1,730개 파일 (4.65 MiB)
- **상태**: ✅ 배포 완료

### 🎯 프로젝트 현황
- ✅ 독립적인 Git 저장소 생성 완료
- ✅ 예제 프로젝트 정리 (DappSample만 유지)
- ✅ 빌드 오류 해결 및 정상 동작 확인
- ✅ GitHub 저장소 배포 완료
- ✅ 개발 환경 준비 완료

### 🧹 GitHub Actions 및 워크플로우 정리
CrossSDKSwift 독립 프로젝트에 맞게 불필요한 CI/CD 워크플로우를 제거했습니다.

### 🗑️ 제거된 워크플로우
- **CI 워크플로우** (`ci.yml`) - Reown 관련 테스트 및 빌드
- **CD 워크플로우** (`cd.yml`) - 자동 버전 설정 및 CocoaPods 린트
- **릴리즈 워크플로우** (`release.yml`) - 샘플 앱 자동 배포
- **빌드 아티팩트** (`build_artifacts.yml`) - 아티팩트 빌드 및 업로드
- **CocoaPods 배포** (`cocoapods.yml`) - 자동 CocoaPods 배포

### 🗂️ 제거된 디렉토리
- `.github/actions/` - 커스텀 GitHub Actions
- `.github/scripts/` - 자동화 스크립트들
- `.github/workflows/` - 모든 워크플로우 파일

### ✅ 남은 GitHub 설정
- `.github/ISSUE_TEMPLATE/` - 이슈 템플릿 (유지)
- `.github/pull_request_template.md` - PR 템플릿 (유지)

### 📋 정리 결과
- **9개 파일 제거** (433줄 → 17줄)
- **프로젝트 구조 단순화**
- **CrossSDKSwift에 맞는 최소한의 GitHub 설정만 유지**

### 📦 CocoaPods 설정 업데이트
기존 Reown 관련 CocoaPods 설정을 CrossSDKSwift용으로 완전히 업데이트했습니다.

### 🔄 주요 변경사항
- **파일명 변경**: `reown-swift.podspec` → `cross-sdk-swift.podspec`
- **패키지명 변경**: `reown-swift` → `cross-sdk-swift`
- **기본 subspec**: `CrossSDKSwift`로 설정
- **저장소 정보**: `https://github.com/to-nexus/cross-sdk-swift`로 업데이트
- **작성자**: `NEXUS`로 변경
- **설명**: CrossSDKSwift의 목적에 맞게 업데이트

### 📝 CrossSDKSwift Subspec
```ruby
spec.subspec 'CrossSDKSwift' do |ss|
  ss.source_files = 'Sources/CrossSDKSwift/**/*.{h,m,swift}'
  ss.dependency 'cross-sdk-swift/CrossAppKit'
  ss.dependency 'cross-sdk-swift/WalletConnectSign'
  ss.resource_bundles = {
    'CrossSDKSwift' => ['Sources/CrossSDKSwift/Resources/*']
  }
end
```

### ✅ 사용법
이제 CocoaPods를 통해 CrossSDKSwift를 설치할 수 있습니다:
```ruby
pod 'cross-sdk-swift'  # 기본으로 CrossSDKSwift subspec 설치
```

### 🔍 검증 완료
- ✅ `pod spec lint` 통과 (버전 1.1.1)
- ✅ 모든 의존성 정상 설정
- ✅ CrossSDKSwift 기본 subspec 동작 확인

---

## [Unreleased] - Reown Prefix 제거 및 모듈명 변경

### 🔄 주요 변경사항
Reown prefix를 제거하여 더 간결한 모듈명을 사용하고, 시스템 프레임워크와의 충돌을 해결했습니다.

### 📁 디렉토리 구조 변경
```
Sources/ReownAppKit/          → Sources/CrossAppKit/
Sources/ReownAppKitUI/        → Sources/AppKitUI/
Sources/ReownAppKitBackport/  → Sources/AppKitBackport/
Sources/ReownWalletKit/       → Sources/WalletKit/
Sources/ReownRouter/          → Sources/CrossRouter/
```

### 📦 Package.swift 변경
- **라이브러리명 변경**:
  - `ReownAppKit` → `CrossAppKit`
  - `ReownAppKitUI` → `AppKitUI` 
  - `ReownWalletKit` → `WalletKit`
  - `ReownRouter` → `CrossRouter`

- **타겟 설정 업데이트**:
  - 모든 타겟의 path 경로 변경
  - CrossSDKSwift 의존성을 새로운 모듈명으로 업데이트

### 🏗️ CocoaPods 설정 변경 (reown-swift.podspec)
- **subspec 이름 변경**:
  - `ReownAppKit` → `CrossAppKit`
  - `ReownRouter` → `CrossRouter`
- **source_files 경로 업데이트**
- **dependency 참조 수정**

### 📝 Import 구문 변경
모든 Swift 파일에서 import 구문 업데이트:
```swift
// 이전
import ReownAppKit
import ReownAppKitUI
import ReownWalletKit
import ReownRouter

// 변경 후
import CrossAppKit
import AppKitUI
import WalletKit
import CrossRouter
```

### 🔧 시스템 충돌 해결

#### macOS AppKit 충돌 해결
- `AppKit` → `CrossAppKit`로 변경하여 시스템 AppKit과 충돌 방지
- `Sources/WalletConnectRelay/AppStateObserving.swift`에서는 시스템 AppKit 사용 유지

#### Router 모듈 충돌 해결
- `Router` → `CrossRouter`로 변경하여 시스템 Router 모듈과 충돌 방지

### ⚙️ Objective-C 모듈 설정
- `Sources/CrossRouter/RouterLegacy/include/module.modulemap`:
  ```objc
  module CrossRouter {
      header "Router.h"
  }
  ```

### 🏷️ 클래스명 변경
- `ReownRouter` 구조체 → `CrossRouter` 구조체
- 모든 `ReownRouter.goBack()` 호출 → `CrossRouter.goBack()` 호출

### 📤 Export 구문 업데이트
Web3ModalImports 파일들에서 @_exported import 구문 수정:
```swift
// Sources/CrossAppKit/Web3ModalImports.swift
@_exported import AppKitUI
@_exported import AppKitBackport

// Sources/CrossRouter/Router/RouterImports.swift  
@_exported import CrossRouter
```

### 🧪 검증 완료
- ✅ 모든 Swift 파일 문법 체크 통과
- ✅ CrossSDKSwift 모듈 빌드 성공
- ✅ 시스템 프레임워크와 충돌 없음
- ✅ 모든 import 구문 정상 작동

### 📚 최종 모듈 구조
```swift
import CrossAppKit     // 메인 AppKit (시스템 충돌 해결)
import AppKitUI        // UI 컴포넌트 (충돌 위험 낮아 이름 유지)
import AppKitBackport  // SwiftUI 백포트 (충돌 위험 낮아 이름 유지)
import WalletKit       // 이전: ReownWalletKit
import CrossRouter     // URL 라우팅 (시스템 충돌 해결)
import CrossSDKSwift   // 변경 없음
```

### ⚠️ 주의사항
- 이 변경으로 인해 기존에 Reown prefix를 사용하던 코드는 업데이트가 필요합니다
- CocoaPods 사용 시 새로운 subspec 이름을 사용해야 합니다
- 시스템 프레임워크와의 충돌이 완전히 해결되었습니다

---
*작업 완료일: 2025년 1월*
