#!/bin/bash

# CrossSDKSwift 릴리즈 스크립트
# 사용법: ./scripts/release.sh 1.0.0

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "❌ 버전을 입력하세요. 예: ./scripts/release.sh 1.0.0"
    exit 1
fi

echo "🚀 CrossSDKSwift v$VERSION 릴리즈 준비 중..."

# 1. 현재 브랜치가 main인지 확인
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "❌ main 브랜치에서만 릴리즈할 수 있습니다. 현재: $CURRENT_BRANCH"
    exit 1
fi

# 2. 작업 디렉토리가 깨끗한지 확인
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ 커밋되지 않은 변경사항이 있습니다. 먼저 커밋하세요."
    git status --short
    exit 1
fi

# 3. 원격 저장소에서 최신 상태 가져오기
echo "🔄 원격 저장소에서 최신 상태 가져오는 중..."
git fetch origin
git pull origin main

# 4. 테스트 실행
echo "🧪 테스트 실행 중..."
swift test

# 5. 버전 정보 업데이트
echo "📝 버전 정보 업데이트 중..."
echo "{\"version\": \"$VERSION\"}" > Sources/WalletConnectRelay/PackageConfig.json

# 6. Podspec 검증
echo "🔍 Podspec 검증 중..."
pod spec lint cross-sdk-swift.podspec --allow-warnings

# 7. 변경사항 커밋
echo "💾 버전 정보 커밋 중..."
git add Sources/WalletConnectRelay/PackageConfig.json
git commit -m "chore: bump version to $VERSION" || echo "변경사항이 없습니다."

# 8. 태그 생성
echo "🏷️ Git 태그 생성 중..."
git tag -a "$VERSION" -m "Release version $VERSION"

# 9. 원격 저장소에 푸시
echo "⬆️ 원격 저장소에 푸시 중..."
git push origin main
git push origin "$VERSION"

echo "✅ 릴리즈 준비 완료!"
echo ""
echo "다음 단계:"
echo "1. GitHub Actions가 자동으로 XCFramework를 빌드하고 릴리즈를 생성합니다."
echo "2. CocoaPods 배포: pod trunk push cross-sdk-swift.podspec --allow-warnings"
echo "3. GitHub에서 릴리즈 노트를 확인하고 수정하세요."
echo ""
echo "🔗 GitHub 릴리즈: https://github.com/to-nexus/cross-sdk-swift/releases/tag/$VERSION"
