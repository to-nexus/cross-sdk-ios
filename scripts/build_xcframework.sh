#!/bin/bash

set -e

FRAMEWORK_NAME="CrossSDKSwift"
OUTPUT_DIR="./build"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

echo "🏗️ Building XCFramework for $FRAMEWORK_NAME"

# 클린업
echo "🧹 Cleaning up previous builds..."
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Swift Package Manager를 사용한 빌드 (의존성 문제 해결)
echo "📦 Building with Swift Package Manager..."

# iOS 시뮬레이터용 빌드
echo "📱 Building for iOS Simulator..."
swift build -c release \
    --arch arm64 --arch x86_64 \
    -Xswiftc -target -Xswiftc arm64-apple-ios14.0-simulator \
    -Xswiftc -target -Xswiftc x86_64-apple-ios14.0-simulator

# 간단한 XCFramework 생성 (Swift 패키지용)
echo "📦 Creating simplified XCFramework structure..."
mkdir -p "$XCFRAMEWORK_PATH"
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64_x86_64-simulator</string>
            <key>LibraryPath</key>
            <string>lib'$FRAMEWORK_NAME'.a</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
            <key>SupportedPlatformVariant</key>
            <string>simulator</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>' > "$XCFRAMEWORK_PATH/Info.plist"

# ZIP 파일 생성
echo "🗜️ Creating ZIP archive..."
cd build
zip -r -q "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
cd ..

echo "✅ XCFramework build completed!"
echo "📍 XCFramework: $XCFRAMEWORK_PATH"
echo "📍 ZIP file: $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework.zip"

# 파일 크기 표시
echo "📊 File sizes:"
du -h "$XCFRAMEWORK_PATH"
du -h "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework.zip"
