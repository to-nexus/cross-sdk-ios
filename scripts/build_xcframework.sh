#!/bin/bash

set -e

FRAMEWORK_NAME="CrossSDKSwift"
OUTPUT_DIR="./build"

echo "🏗️ Creating Distribution Package for $FRAMEWORK_NAME"

# 클린업
echo "🧹 Cleaning up previous builds..."
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

echo "📋 Creating documentation and examples..."

# README 생성
cat > "$OUTPUT_DIR/README.md" << 'EOF'
# CrossSDKSwift Distribution Package

## 🚀 Installation

### Swift Package Manager (Recommended)

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-swift", from: "1.0.0")
]
```

### CocoaPods

Add this to your `Podfile`:

```ruby
pod 'cross-sdk-swift', '~> 1.0.0'
```

## 📚 Quick Start

```swift
import CrossSDKSwift

// Initialize
CrossSDKSwift.shared.initialize(projectId: "your-project-id")

// Connect wallet
try await CrossSDKSwift.shared.connect()

// Use utilities
let isValid = CrossSDKSwift.shared.utils.isValidAddress("0x...")
let formatted = CrossSDKSwift.shared.utils.formatAddress("0x...")
```

## ⚠️ Note

XCFramework is currently not available due to cryptographic library dependency issues.
Please use Swift Package Manager for the best experience.

## 📖 Documentation

For complete documentation, visit: https://github.com/to-nexus/cross-sdk-swift
EOF

# 간단한 예제 생성
mkdir -p "$OUTPUT_DIR/Examples"
cat > "$OUTPUT_DIR/Examples/BasicUsage.swift" << 'EOF'
import CrossSDKSwift
import Foundation

class WalletManager {
    func setupWallet() async {
        // Initialize CrossSDKSwift
        CrossSDKSwift.shared.initialize(projectId: "your-project-id")
        
        do {
            // Connect to wallet
            try await CrossSDKSwift.shared.connect()
            print("✅ Wallet connected successfully")
            
            // Use utility functions
            let testAddress = "0x742d35Cc6634C0532925a3b8D2e8f5B4c1234567"
            let isValid = CrossSDKSwift.shared.utils.isValidAddress(testAddress)
            let formatted = CrossSDKSwift.shared.utils.formatAddress(testAddress)
            
            print("Address valid: \(isValid)")
            print("Formatted: \(formatted)")
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
}
EOF

# 버전 정보
echo "1.0.0" > "$OUTPUT_DIR/VERSION"

# 라이센스 복사
if [ -f "LICENSE" ]; then
    cp LICENSE "$OUTPUT_DIR/"
fi

# 변경로그 복사
if [ -f "CHANGELOG.md" ]; then
    cp CHANGELOG.md "$OUTPUT_DIR/"
fi

echo "🗜️ Creating distribution archive..."
zip -r -q "CrossSDKSwift-v1.0.0-Distribution.zip" build/

echo "✅ Distribution package created successfully!"
echo ""
echo "📦 Package Contents:"
echo "├── README.md           - Installation and usage guide"
echo "├── Examples/           - Code examples"
echo "│   └── BasicUsage.swift"
echo "├── VERSION             - Version information"
echo "├── LICENSE             - License file"
echo "└── CHANGELOG.md        - Change history"
echo ""
echo "📍 Archive: CrossSDKSwift-v1.0.0-Distribution.zip"
echo "📊 Size: $(du -h CrossSDKSwift-v1.0.0-Distribution.zip | cut -f1)"
echo ""
echo "🎯 Installation:"
echo "1. Use Swift Package Manager (recommended):"
echo "   .package(url: \"https://github.com/to-nexus/cross-sdk-swift\", from: \"1.0.0\")"
echo ""
echo "2. Or CocoaPods:"
echo "   pod 'cross-sdk-swift', '~> 1.0.0'"
