# CrossSDKSwift

A comprehensive SDK for Web3 DApp development on iOS. Provides wallet connection, chain management, signing, and transaction functionality using the WalletConnect protocol.

## Key Features

- Wallet connection and session management
- SwiftUI `@ObservedObject` support
- Multi-chain support (Cross, BSC, Kaia, Ethereum)
- Signing capabilities (Personal Sign, ETH Sign, EIP-712 Typed Data)
- Transaction sending (Native/ERC-20)
- Balance queries
- Transaction receipt polling
- Automatic completion detection and status checking
- Event log parsing
- Utility functions

## Requirements
- iOS 13.0+
- Xcode 13.0+
- Swift 5.5+

## Supported Features

### Wallet Connection
- Wallet connection via `connectWallet()` function
- Connection state tracking (`connected`, `connecting`, `disconnected`)
- Session recovery on app restart
- Automatic wallet app switching

### Multi-Chain Support
```swift
.crossMainnet, .crossTestnet    // Cross Network
.bscMainnet, .bscTestnet        // Binance Smart Chain  
.kaiaMainnet, .kaiaTestnet      // Kaia (Klaytn)
.ethereum, .sepolia             // Ethereum
```

### Signing Capabilities
- Personal Sign: Sign text messages
- ETH Sign: Sign raw byte data
- EIP-712 Typed Data: Sign structured data
- Signature verification and address recovery

### Transactions
- Native token transfers
- ERC-20 token transfers
- Dynamic fees (EIP-1559)
- Balance queries
- Smart contract function calls
- Transaction receipt polling
- Automatic completion detection and status checking

### Utilities
- Address validation and formatting
- Hex/decimal conversion
- Wei unit conversion
- Error handling

## Installation

### Swift Package Manager
In Xcode, select File → Add Package Dependencies and enter the following URL:
```
https://github.com/to-nexus/cross-sdk-swift
```

Add directly to Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/to-nexus/cross-sdk-swift", from: "1.0.0")
]
```

## Initial Setup

### WalletConnect Project ID
Create a project at [WalletConnect Cloud](https://cloud.walletconnect.com/) to obtain your Project ID.

### URL Scheme Configuration
Set up URL Scheme for returning from wallet apps.

Configure in Xcode:
1. Target → Info → URL Types
2. Click "+" button
3. URL Schemes: Unique app scheme (e.g., `mydapp`)
4. Identifier: App bundle ID

Add directly to Info.plist:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>mydapp</string>
        </array>
    </dict>
</array>
```

### App Initialization
```swift
import SwiftUI
import CrossSDKSwift

@main
struct MyApp: App {
    init() {
        CrossSDKSwift.shared.configure(
            projectId: "YOUR_PROJECT_ID",
            groupIdentifier: "group.com.yourcompany.yourapp",
            appName: "My DApp",
            appDescription: "Web3 application",
            appUrl: "https://mydapp.com",
            iconUrls: ["https://mydapp.com/icon.png"],
            redirectNative: "mydapp://",
            redirectUniversal: "https://mydapp.com/redirect",
            supportedChains: [.ethereum, .polygon, .crossMainnet]
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("Received URL: \(url)")
                }
        }
    }
}
```

## Usage

### 1. Basic UI Setup
```swift
import SwiftUI
import CrossSDKSwift

struct ContentView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared
    
    var body: some View {
        VStack(spacing: 20) {
            switch sdk.connectionState {
            case .connected(let wallet):
                Text("Connected: \(sdk.utils.formatAddress(wallet.address))")
                Text("Chain: \(wallet.chain.name)")
            case .connecting:
                Text("Connecting")
            case .disconnected:
                Text("Disconnected")
            }
            if sdk.isConnected {
                Button("Disconnect Wallet") {
                    Task { try? await sdk.disconnectWallet() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Connect Wallet") {
                    Task { try? await sdk.connectWallet() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

### 2. Wallet Connection
```swift
try await CrossSDKSwift.shared.connectWallet()
try await CrossSDKSwift.shared.switchChain(to: .ethereum)

if CrossSDKSwift.shared.isConnected {
    let wallet = CrossSDKSwift.shared.connectedWallet
    print("Address: \(wallet?.address ?? "")")
    print("Chain: \(wallet?.chain.name ?? "")")
}
```

### 3. Message Signing
```swift
// Personal Sign
let result = try await CrossSDKSwift.shared.personalSign(
    message: "Hello, CrossSDKSwift!",
    customData: CustomData(string: "metadata")
)

// EIP-712 Typed Data
let typedData = EIP712TypedData(
    domain: EIP712Domain(name: "MyDApp", version: "1.0.0"),
    primaryType: "Message",
    types: ["Message": [EIP712Type(name: "content", type: "string")]],
    message: ["content": AnyCodable("Hello World")]
)

let result = try await CrossSDKSwift.shared.signTypedDataV4(
    typedData: typedData,
    customData: CustomData(object: ["timestamp": Date().timeIntervalSince1970])
)
```

### 4. Transaction Sending

#### Basic Sending (Hash Only)
```swift
// Native token transfer - Quick response
let txHash: String = try await CrossSDKSwift.shared.sendNative(
    to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
    amount: "0.01"
)
print("Transaction sent: \(txHash)")

// General transaction sending
let params = CrossTransactionParams(
    to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
    value: "0.01"
)
let txHash: String = try await CrossSDKSwift.shared.sendTransaction(params)
```

#### Complete Sending (Wait for Receipt)
```swift
// Native token transfer + Receipt polling
let receipt: CrossTransactionReceipt = try await CrossSDKSwift.shared.sendNative(
    to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
    amount: "0.01"
)

// Check transaction completion status
if receipt.receiptStatus == .success {
    print("✅ Transaction successful!")
    print("📄 Block number: \(receipt.blockNumber ?? "N/A")")
    print("⛽ Gas used: \(receipt.gasUsed)")
    print("💰 Effective gas price: \(receipt.effectiveGasPrice ?? "N/A")")
} else {
    print("❌ Transaction failed")
}

// General transaction + Receipt polling
let params = CrossTransactionParams(
    to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
    value: "0.01"
)
let receipt: CrossTransactionReceipt = try await CrossSDKSwift.shared.sendTransaction(params)

// Utilize detailed receipt information
print("📊 Receipt information:")
print("  - Status: \(receipt.receiptStatus)")
print("  - Block hash: \(receipt.blockHash ?? "N/A")")
print("  - Transaction index: \(receipt.transactionIndex ?? 0)")
print("  - Event logs: \(receipt.logs.count) logs")

// Process event logs
for log in receipt.logs {
    print("📝 Event: \(log.address) - \(log.topics.count) topics")
}
```

### 5. Balance Queries
```swift
let nativeBalance = try await CrossSDKSwift.shared.fetchNativeBalance()
let tokenBalance = try await CrossSDKSwift.shared.fetchERC20Balance(
    contractAddress: "0xA0b86a33E6441c0c11f2f82c7A1d0D9c5d5A5A5A"
)
```

### 6. Smart Contracts

#### Contract Reading (view functions)
```swift
let balanceHex = try await CrossSDKSwift.shared.transactionManager.readContract(
    contractAddress: "0xContractAddress",
    methodName: "balanceOf",
    abi: "balanceOf(address)",
    params: ["0xUserAddress"]
)
```

#### Contract Writing - Basic (Hash Only)
```swift
// Quick contract call
let txHash: String = try await CrossSDKSwift.shared.writeContract(
    contractAddress: "0xContractAddress",
    methodName: "transfer",
    abi: "transfer(address,uint256)",
    params: ["0xRecipient", "1000000000000000000"],
    value: "0"
)
print("Contract called: \(txHash)")
```

#### Contract Writing - Complete Call (Wait for Receipt)
```swift
// ERC-20 token transfer + Receipt confirmation
let receipt: CrossTransactionReceipt = try await CrossSDKSwift.shared.writeContract(
    contractAddress: "0xTokenContract",
    methodName: "transfer",
    abi: "transfer(address,uint256)",
    params: ["0xRecipient", "1000000000000000000"],
    value: "0"
)

// Check contract call result
if receipt.receiptStatus == .success {
    print("✅ Token transfer successful!")
    
    // Find Transfer event logs
    for log in receipt.logs {
        if log.topics.count >= 3 {
            // Transfer(address indexed from, address indexed to, uint256 value)
            let from = log.topics[1]
            let to = log.topics[2] 
            print("📝 Transfer: \(from) → \(to)")
        }
    }
} else {
    print("❌ Token transfer failed")
}

// NFT minting example
let mintReceipt: CrossTransactionReceipt = try await CrossSDKSwift.shared.writeContract(
    contractAddress: "0xNFTContract",
    methodName: "mint",
    abi: "mint()",
    value: "0.01" // Send ETH for payable functions
)

// Check minting success and gas costs
print("🎨 NFT minting completed!")
print("⛽ Gas used: \(mintReceipt.gasUsed)")
print("💰 Gas cost: \(mintReceipt.effectiveGasPrice ?? "N/A")")
```

#### Receipt Polling Configuration (Advanced)
```swift
// Custom polling configuration
let config = CrossReceiptPollingConfig(
    maxAttempts: 60,        // Maximum 60 attempts
    intervalSeconds: 2.0,   // 2-second intervals
    timeoutSeconds: 120.0   // 2-minute timeout
)

let receipt = try await CrossSDKSwift.shared.transactionManager.sendTransactionAndWaitForReceipt(
    params,
    config: config
)
```

## UI Components

### Wallet Components
```swift
struct MyWalletView: View {
    var body: some View {
        CrossSDKWalletKit(
            showNetworkButton: true,
            showAccountInfo: true
        )
    }
}
```

### Individual Components
```swift
CrossSDKConnectButton()
CrossSDKNetworkSelector()
SocketStatusView()
```

## Utility Functions

### Address-related
```swift
let utils = CrossSDKSwift.shared.utils

let isValid = utils.isValidAddress("0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58")
let formatted = utils.formatAddress("0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58")
```

### Data Conversion
```swift
let decimal = utils.hexToDecimal("0xff")
let hex = utils.decimalStringToHex("255")

let data = try utils.encodeERC20TransferData(
    to: "0xRecipient",
    amount: "100.5", 
    decimals: 18
)
```

## Example App

```bash
open Example/DappSample/DappSample.xcodeproj
```

Example screens:
- `SigningExampleView`: Signing functionality
- `SendExampleView`: Transfer functionality
- `BalanceExampleView`: Balance queries
- `CrossSDKWalletKit`: Wallet components

## Advanced Configuration

### Custom Chains
```swift
extension CrossChain {
    static let myCustomChain = CrossChain(
        name: "My Chain",
        chainId: "12345",
        rpcUrl: "https://rpc.mychain.com",
        symbol: "MYC",
        decimals: 18,
        blockExplorer: "https://explorer.mychain.com"
    )
}

CrossSDKSwift.shared.configure(
    supportedChains: [.ethereum, .myCustomChain]
)
```

### Error Handling
```swift
do {
    let result = try await CrossSDKSwift.shared.connectWallet()
} catch CrossSDKError.userRejected {
    print("User rejected")
} catch CrossSDKError.networkError(let message) {
    print("Network error: \(message)")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

#### Receipt Polling Error Handling
```swift
do {
    let receipt = try await CrossSDKSwift.shared.sendNative(
        to: "0x742d35Cc6634C0532925a3b8D4C9db96B47D9a58",
        amount: "0.01"
    )
    print("Transaction completed: \(receipt.receiptStatus)")
} catch CrossSDKError.receiptPollingTimeout {
    print("⏰ Receipt polling timeout - Transaction not yet mined")
} catch CrossSDKError.invalidReceiptData {
    print("📄 Invalid receipt data")
} catch CrossSDKError.rpcRequestFailed(let message) {
    print("🌐 RPC request failed: \(message)")
} catch {
    print("Error: \(error.localizedDescription)")
}

// Handle receipt status
if let receipt = try? await CrossSDKSwift.shared.sendNative(to: address, amount: amount) {
    switch receipt.receiptStatus {
    case .success:
        print("✅ Transaction successful!")
        // Success logic
    case .failure:
        print("❌ Transaction failed - Out of gas or reverted")
        // Failure logic
    }
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Please read our contributing guidelines and code of conduct before submitting pull requests.

## Support

For support and questions:
- Create an issue on GitHub
- Check our documentation
- Review the example app

---

**CrossSDKSwift** - Making Web3 development on iOS simple and powerful! 🚀