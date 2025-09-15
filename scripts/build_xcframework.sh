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

# iOS 시뮬레이터용 빌드
echo "📱 Building for iOS Simulator..."
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$OUTPUT_DIR/ios-simulator.xcarchive" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

# iOS 디바이스용 빌드  
echo "📱 Building for iOS Device..."
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS" \
    -archivePath "$OUTPUT_DIR/ios-device.xcarchive" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

# XCFramework 생성
echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$OUTPUT_DIR/ios-simulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -framework "$OUTPUT_DIR/ios-device.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -output "$XCFRAMEWORK_PATH"

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
