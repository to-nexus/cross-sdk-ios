# CrossSDKSwift 배포 가이드

이 문서는 CrossSDKSwift를 Swift Package Manager로 배포하기 위한 단계별 가이드입니다.

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

## 2. 자동화 설정 (GitHub Actions)

### 2.1 워크플로우 파일 생성
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
    
```

## 3. 배포 체크리스트

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

## 4. 사용자 가이드 업데이트

### README.md에 설치 방법 추가
```markdown
## 설치

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-swift", from: "1.0.0")
]
```

## 5. 버전 관리 전략

### Semantic Versioning 적용
- **MAJOR** (1.0.0): 호환성이 깨지는 변경
- **MINOR** (1.1.0): 기능 추가 (하위 호환)
- **PATCH** (1.0.1): 버그 수정

### 브랜치 전략
- `main`: 안정 버전
- `develop`: 개발 버전
- `release/x.x.x`: 릴리즈 준비
- `hotfix/x.x.x`: 긴급 수정

## 6. 문제 해결

### 일반적인 문제들
1. **SPM 설치 실패**: Git 태그 확인
2. **의존성 해결 실패**: Package.swift 확인

### 디버깅 명령어
```bash
# SPM 캐시 클리어
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/org.swift.swiftpm/

# Xcode 파생 데이터 클리어
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Package 해결 확인
swift package resolve
swift package dump-package
```
