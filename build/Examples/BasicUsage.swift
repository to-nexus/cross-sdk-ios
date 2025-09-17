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
