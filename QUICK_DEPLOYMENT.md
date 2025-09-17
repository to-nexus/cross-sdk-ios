# CrossSDKSwift 빠른 배포 가이드

## 🚀 한 번에 배포하기

### 1단계: 릴리즈 스크립트 실행
```bash
# 원하는 버전으로 릴리즈
./scripts/release.sh 1.0.0
```

이 스크립트가 자동으로 수행하는 작업:
- ✅ 브랜치 및 작업 디렉토리 상태 확인
- ✅ 테스트 실행
- ✅ 버전 정보 업데이트
- ✅ Podspec 검증
- ✅ Git 태그 생성 및 푸시

### 2단계: GitHub Actions 완료 대기
- GitHub에서 자동으로 릴리즈 생성
- GitHub Release 자동 생성
- 진행 상황: https://github.com/to-nexus/cross-sdk-swift/actions

### 3단계: CocoaPods 배포 (수동)
```bash
# CocoaPods Trunk 등록 (처음 한 번만)
pod trunk register your-email@example.com 'Your Name'

# CocoaPods에 배포
pod trunk push cross-sdk-swift.podspec --allow-warnings
```

## 📋 배포 상태 확인

### SPM 배포 확인
```swift
// Package.swift에서 테스트
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-swift", from: "1.0.0")
]
```

### CocoaPods 배포 확인
```bash
pod search cross-sdk-swift
```

### 배포 확인
- GitHub Releases에서 릴리즈가 생성되었는지 확인

## 🔧 현재 배포 상태

### ✅ 준비 완료
- [x] Package.swift (SPM)
- [x] cross-sdk-swift.podspec (CocoaPods) - 검증 완료
- [x] 배포 패키지 스크립트
- [x] GitHub Actions 워크플로우
- [x] 릴리즈 자동화 스크립트

### 📦 배포 방법별 현황

| 배포 방법 | 상태 | 명령어 |
|-----------|------|--------|
| **SPM** | ✅ 준비완료 | `./scripts/release.sh 1.0.0` |
| **CocoaPods** | ✅ 준비완료 | `pod trunk push cross-sdk-swift.podspec --allow-warnings` |

## 🎯 다음 릴리즈 준비사항

### 버전 업데이트 시 수행할 작업
1. CHANGELOG.md 업데이트
2. README.md의 버전 정보 업데이트 (필요시)
3. 테스트 코드 실행 및 검증
4. `./scripts/release.sh [VERSION]` 실행

### 핫픽스 배포
```bash
# 핫픽스 브랜치에서
./scripts/release.sh 1.0.1
```

## 🚨 문제 해결

### 일반적인 문제
1. **Podspec 검증 실패**
   ```bash
   pod spec lint cross-sdk-swift.podspec --verbose
   ```

2. **GitHub Actions 실패**
   - Actions 탭에서 로그 확인
   - 필요시 태그 재생성

3. **Git 태그 충돌**
   ```bash
   git tag -d 1.0.0  # 로컬 태그 삭제
   git push origin :refs/tags/1.0.0  # 원격 태그 삭제
   ```

### 수동 배포 (비상시)

#### SPM만 배포
```bash
git tag 1.0.0
git push origin 1.0.0
```

#### CocoaPods만 배포
```bash
pod trunk push cross-sdk-swift.podspec --allow-warnings
```

#### 배포 패키지만 생성
```bash
./scripts/build_xcframework.sh
# 문서 패키지 생성
```

## 📊 배포 후 확인사항

- [ ] GitHub Release 생성됨
- [ ] 릴리즈 노트 생성됨
- [ ] CocoaPods에서 검색 가능
- [ ] SPM으로 설치 가능
- [ ] 예제 프로젝트에서 새 버전 동작 확인

---

**현재 CrossSDKSwift는 SPM과 CocoaPods 배포가 준비되어 있습니다!** 
`./scripts/release.sh 1.0.0` 명령어 하나로 SPM 배포가 완료되며, CocoaPods는 한 번의 추가 명령어로 배포할 수 있습니다.
