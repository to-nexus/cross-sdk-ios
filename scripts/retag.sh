#!/bin/bash

set -e

echo "🏷️ Git 태그 재설정 스크립트"
echo ""

# 현재 태그 확인
echo "📋 현재 태그 목록:"
git tag -l

echo ""
echo "🗑️ 기존 태그 제거 중..."

# 로컬 태그 모두 제거
git tag -l | xargs -n 1 git tag -d

# 원격 태그 제거 (있다면)
echo "🌐 원격 태그 제거 중..."
git ls-remote --tags origin | awk '{print $2}' | sed 's|refs/tags/||' | xargs -I {} git push origin :refs/tags/{}

echo ""
echo "✨ 새 태그 생성 중..."

# 새 태그 생성
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
    .package(url: \"https://github.com/to-nexus/cross-sdk-ios\", from: \"1.0.0\")
]

⚠️ Breaking Changes:
- CocoaPods 지원 중단
- XCFramework 지원 중단
- Swift Package Manager 전용으로 변경"

echo ""
echo "🚀 원격 저장소에 태그 푸시 중..."
git push origin 1.0.0

echo ""
echo "✅ 태그 재설정 완료!"
echo ""
echo "📋 새로운 태그:"
git tag -l
echo ""
echo "🎯 사용법:"
echo "Swift Package Manager:"
echo ".package(url: \"https://github.com/to-nexus/cross-sdk-ios\", from: \"1.0.0\")"
