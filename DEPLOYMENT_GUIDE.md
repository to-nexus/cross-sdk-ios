# CrossSDKSwift 배포 가이드

이 문서는 CrossSDKSwift를 SPM과 CocoaPods로 배포하기 위한 단계별 가이드입니다.

## 1. Swift Package Manager (SPM) 배포

### 현재 상태
- ✅ `Package.swift` 파일 존재
- ✅ GitHub 저장소 설정 완료

### 배포 단계

#### 1.1 버전 태깅
```bash
# 버전 태그 생성 (semantic versioning)
git tag -a 1.0.0 -m "Release version 1.0.0"
git push origin 1.0.0

# 모든 태그 푸시
git push origin --tags
```

#### 1.2 릴리즈 생성
GitHub에서 Release 생성:
1. GitHub 저장소 → Releases → Create a new release
2. Tag version: `1.0.0`
3. Release title: `CrossSDKSwift v1.0.0`
4. 릴리즈 노트 작성

#### 1.3 사용법 검증
```swift
// Package.swift에 추가
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-swift", from: "1.0.0")
]
```

## 2. CocoaPods 배포

### 현재 상태
- ✅ `cross-sdk-swift.podspec` 파일 존재
- ✅ 모든 subspec 정의 완료

### 배포 단계

#### 2.1 버전 정보 업데이트
`Sources/WalletConnectRelay/PackageConfig.json` 파일 확인:
```json
{
  "version": "1.0.0"
}
```

#### 2.2 Podspec 검증
```bash
# Podspec 문법 검증
pod spec lint cross-sdk-swift.podspec

# 의존성 포함 검증 (더 엄격)
pod spec lint cross-sdk-swift.podspec --allow-warnings
```

#### 2.3 CocoaPods Trunk 등록
```bash
# 처음 한 번만 실행 (이미 등록되어 있다면 생략)
pod trunk register your-email@example.com 'Your Name'

# 이메일 인증 후 세션 확인
pod trunk me
```

#### 2.4 CocoaPods에 배포
```bash
# 배포 실행
pod trunk push cross-sdk-swift.podspec

# 경고 무시하고 배포 (필요시)
pod trunk push cross-sdk-swift.podspec --allow-warnings
```

#### 2.5 배포 확인
```bash
# 검색으로 확인
pod search cross-sdk-swift

# 또는 직접 설치 테스트
pod install --repo-update
```

## 3. 자동화 설정 (GitHub Actions)

### 3.1 워크플로우 파일 생성
`.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - '*'

jobs:
  release:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Validate Package
      run: |
        swift package resolve
        swift package dump-package > /dev/null
    
    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        generate_release_notes: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Deploy to CocoaPods
      env:
        COCOAPODS_TRUNK_TOKEN: ${{ secrets.COCOAPODS_TRUNK_TOKEN }}
      run: |
        pod trunk push cross-sdk-swift.podspec --allow-warnings
```

### 4.2 시크릿 설정
GitHub 저장소 → Settings → Secrets and variables → Actions:
- `COCOAPODS_TRUNK_TOKEN`: CocoaPods 토큰 추가

## 5. 배포 체크리스트

### 릴리즈 전 체크리스트
- [ ] 모든 테스트 통과
- [ ] 버전 번호 업데이트 (`PackageConfig.json`)
- [ ] CHANGELOG.md 업데이트
- [ ] README.md 업데이트
- [ ] 예제 앱 동작 확인

### SPM 배포 체크리스트
- [ ] `Package.swift` 최신 상태 확인
- [ ] Git 태그 생성
- [ ] GitHub Release 생성
- [ ] SPM으로 설치 테스트

### CocoaPods 배포 체크리스트
- [ ] `podspec` 파일 검증
- [ ] `pod spec lint` 통과
- [ ] CocoaPods Trunk 등록 확인
- [ ] `pod trunk push` 실행
- [ ] CocoaPods에서 검색 확인


## 6. 사용자 가이드 업데이트

### README.md에 설치 방법 추가
```markdown
## 설치

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-swift", from: "1.0.0")
]
```

### CocoaPods
```ruby
pod 'cross-sdk-swift'
```

```

## 7. 버전 관리 전략

### Semantic Versioning 적용
- **MAJOR** (1.0.0): 호환성이 깨지는 변경
- **MINOR** (1.1.0): 기능 추가 (하위 호환)
- **PATCH** (1.0.1): 버그 수정

### 브랜치 전략
- `main`: 안정 버전
- `develop`: 개발 버전
- `release/x.x.x`: 릴리즈 준비
- `hotfix/x.x.x`: 긴급 수정

## 8. 문제 해결

### 일반적인 문제들
1. **CocoaPods 배포 실패**: 의존성 문제 확인
2. **SPM 설치 실패**: Git 태그 확인

### 디버깅 명령어
```bash
# CocoaPods 캐시 클리어
pod cache clean --all

# SPM 캐시 클리어
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/org.swift.swiftpm/

# Xcode 파생 데이터 클리어
rm -rf ~/Library/Developer/Xcode/DerivedData/
```
