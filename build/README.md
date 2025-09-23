# CrossSDKSwift Distribution Package

## 🚀 Installation

### Swift Package Manager (Recommended)

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-ios", from: "1.0.0")
]
```

### CocoaPods

Add this to your `Podfile`:

```ruby
pod 'cross-sdk-ios', '~> 1.0.0'
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

For complete documentation, visit: https://github.com/to-nexus/cross-sdk-ios
