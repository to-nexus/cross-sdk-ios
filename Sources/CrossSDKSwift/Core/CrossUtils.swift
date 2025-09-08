//
//  CrossUtils.swift
//  CrossSDKSwift
//
//  Created by Chuck on 1/5/25.
//

import Foundation
import WalletConnectUtils
import WalletConnectSigner
import Commons
import web3swift
import Web3Core
import CryptoSwift

/// Utility functions for data conversion and formatting
public class CrossUtils {

    // MARK: - Hex Conversion

    /// Convert hex string to Data
    /// - Parameter hex: Hex string (with or without 0x prefix)
    /// - Returns: Data representation of the hex string
    public func hexToData(_ hex: String) -> Data {
        return Data(hexString: hex)
    }

    /// Convert Data to hex string
    /// - Parameter data: Data to convert
    /// - Returns: Hex string without 0x prefix
    public func dataToHex(_ data: Data) -> String {
        return data.toHexString()
    }

    /// Convert Data to hex string with 0x prefix
    /// - Parameter data: Data to convert
    /// - Returns: Hex string with 0x prefix
    public func dataToHexWithPrefix(_ data: Data) -> String {
        return "0x" + data.toHexString()
    }

    // MARK: - Address Formatting

    /// Format Ethereum address for display (shortened version)
    /// - Parameter address: Full Ethereum address
    /// - Returns: Shortened address in format "0x1234...5678"
    public func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }

    /// Validate Ethereum address format
    /// - Parameter address: Address to validate
    /// - Returns: True if address is valid format
    public func isValidAddress(_ address: String) -> Bool {
        let pattern = "^0x[a-fA-F0-9]{40}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: address.utf16.count)
        return regex?.firstMatch(in: address, options: [], range: range) != nil
    }

    // MARK: - String Conversion

    /// Convert string to hex-encoded string
    /// - Parameter string: String to convert
    /// - Returns: Hex representation of the string
    public func stringToHex(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return dataToHex(data)
    }

    /// Convert string to hex with 0x prefix
    /// - Parameter string: String to convert
    /// - Returns: Hex representation with 0x prefix
    public func stringToHexWithPrefix(_ string: String) -> String {
        return "0x" + stringToHex(string)
    }

    /// Convert hex string back to original string
    /// - Parameter hex: Hex string (with or without 0x prefix)
    /// - Returns: Original string if conversion is successful
    public func hexToString(_ hex: String) -> String? {
        let data = hexToData(hex)
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Number Formatting

    /// Format wei amount to ETH with specified decimal places
    /// - Parameters:
    ///   - wei: Wei amount as string
    ///   - decimals: Number of decimal places (default: 4)
    /// - Returns: Formatted ETH amount string
    public func formatWeiToEth(_ wei: String, decimals: Int = 4) -> String {
        guard let weiValue = Double(wei) else { return "0" }
        let ethValue = weiValue / 1_000_000_000_000_000_000 // 10^18
        return String(format: "%.\(decimals)f", ethValue)
    }

    /// Convert ETH amount to wei string
    /// - Parameter eth: ETH amount as string
    /// - Returns: Wei amount as string
    public func ethToWei(_ eth: String) -> String {
        guard let ethValue = Double(eth) else { return "0" }
        let weiValue = ethValue * 1_000_000_000_000_000_000 // 10^18
        return String(format: "%.0f", weiValue)
    }

    // MARK: - Cryptographic Functions

    private let crypto = DefaultCryptoProvider()

    /// Verify personal_sign signature using web3swift
    /// - Parameters:
    ///   - signature: Signature string (with or without 0x prefix)
    ///   - message: Original message that was signed
    ///   - expectedAddress: Expected signer address
    /// - Returns: True if signature is valid and matches expected address
    public func verifyPersonalSign(signature: String, message: String, expectedAddress: String) -> Bool {
        do {
            // Clean signature and expected address
            let cleanSignature = signature.replacingOccurrences(of: "0x", with: "")
            let cleanExpectedAddress = expectedAddress.replacingOccurrences(of: "0x", with: "").lowercased()
            let sigData = Data(hexString: cleanSignature)
            guard sigData.count == 65 else {
                print("❌ Invalid signature format: \(signature)")
                return false
            }

            // Create message hash with EIP-191 prefix
            let messageData = Data(message.utf8)
            let prefixedMessage = "\u{19}Ethereum Signed Message:\n\(messageData.count)\(message)"
            let messageHash = prefixedMessage.data(using: .utf8)!.sha3(.keccak256)

            // Try to recover address using web3swift
            guard let recoveredPublicKey = try SECP256K1.recoverPublicKey(
                hash: messageHash,
                signature: sigData
            ) else {
                print("❌ Failed to recover public key")
                return false
            }
            
            // Get Ethereum address from public key (remove first byte 0x04)
            let publicKeyData = recoveredPublicKey.dropFirst()
            let addressData = publicKeyData.sha3(.keccak256).suffix(20)
            let recoveredAddressString = addressData.toHexString().lowercased()

            print("🔍 Personal Sign Verification:")
            print("   Original message: '\(message)'")
            print("   Message hash: 0x\(messageHash.toHexString())")
            print("   Recovered address: 0x\(recoveredAddressString)")
            print("   Expected address: \(expectedAddress)")

            return recoveredAddressString == cleanExpectedAddress
        } catch {
            print("❌ Personal sign verification error: \(error)")
            return false
        }
    }

    /// Verify eth_sign signature using secp256k1
    /// - Parameters:
    ///   - signature: Signature string (with or without 0x prefix)
    ///   - data: Original data that was signed
    ///   - expectedAddress: Expected signer address
    /// - Returns: True if signature is valid and matches expected address
    public func verifyEthSign(signature: String, data: Data, expectedAddress: String) -> Bool {
        do {
            let cleanSignature = signature.replacingOccurrences(of: "0x", with: "")
            let sigData = Data(hexString: cleanSignature)
            guard sigData.count == 65 else {
                return false
            }

            // Recover public key using web3swift (eth_sign uses raw data hash)
            let messageHash = data.sha3(.keccak256)
            
            guard let recoveredPublicKey = try SECP256K1.recoverPublicKey(
                hash: messageHash,
                signature: sigData
            ) else {
                return false
            }
            
            // Get Ethereum address from public key (remove first byte 0x04)
            let publicKeyData = recoveredPublicKey.dropFirst()
            let addressData = publicKeyData.sha3(.keccak256).suffix(20)
            let recoveredAddress = "0x" + addressData.toHexString()

            return recoveredAddress.lowercased() == expectedAddress.lowercased()
        } catch {
            return false
        }
    }

    /// Verify EIP-712 typed data signature using secp256k1
    /// - Parameters:
    ///   - signature: Signature string (with or without 0x prefix)
    ///   - typedData: EIP-712 typed data that was signed
    ///   - expectedAddress: Expected signer address
    /// - Returns: True if signature is valid and matches expected address
    public func verifyTypedDataV4(signature: String, typedData: EIP712TypedData, expectedAddress: String) -> Bool {
        do {
            let cleanSignature = signature.replacingOccurrences(of: "0x", with: "")
            let sigData = Data(hexString: cleanSignature)
            guard sigData.count == 65 else {
                return false
            }

            // Hash the typed data
            let digest = hashTypedData(typedData)

            // Recover public key using web3swift
            guard let recoveredPublicKey = try SECP256K1.recoverPublicKey(
                hash: digest,
                signature: sigData
            ) else {
                return false
            }

            // Get Ethereum address from public key (remove first byte 0x04)
            let publicKeyData = recoveredPublicKey.dropFirst()
            let addressData = publicKeyData.sha3(.keccak256).suffix(20)
            let recoveredAddress = "0x" + addressData.toHexString()

            return recoveredAddress.lowercased() == expectedAddress.lowercased()
        } catch {
            return false
        }
    }

    /// Recover address from signature using secp256k1
    /// - Parameters:
    ///   - signature: Signature string (with or without 0x prefix)
    ///   - message: Original message that was signed
    ///   - signType: Type of signature (personalSign, ethSign, typedDataV4)
    /// - Returns: Recovered address or nil if recovery fails
    public func recoverAddress(signature: String, message: String, signType: CrossSigningType) -> String? {
        do {
            // Clean signature (remove 0x prefix)
            let cleanSignature = signature.replacingOccurrences(of: "0x", with: "")
            let sigData = Data(hexString: cleanSignature)
            guard sigData.count == 65 else {
                return nil
            }

            let messageHash: Data

            switch signType {
            case .personalSign:
                // EIP-191 personal sign message hash
                let messageData = Data(message.utf8)
                let prefix = Data("\u{19}Ethereum Signed Message:\n\(messageData.count)".utf8)
                let fullMessage = prefix + messageData
                messageHash = fullMessage.sha3(.keccak256)

            case .ethSign:
                // eth_sign uses raw data hash
                let rawData = hexToData(message.replacingOccurrences(of: "0x", with: ""))
                messageHash = rawData.sha3(.keccak256)

            case .ethSignTypedDataV4:
                // For typed data, we need the actual EIP712TypedData object
                // This method is mainly for simple message recovery
                return nil
            }

            // Recover public key using web3swift
            guard let recoveredPublicKey = try SECP256K1.recoverPublicKey(
                hash: messageHash,
                signature: sigData
            ) else {
                print("❌ Failed to recover public key")
                return nil
            }

            // Get Ethereum address from public key (remove first byte 0x04)
            let publicKeyData = recoveredPublicKey.dropFirst()
            let addressData = publicKeyData.sha3(.keccak256).suffix(20)
            let recoveredAddress = "0x" + addressData.toHexString()

            return recoveredAddress
        } catch {
            print("❌ Address recovery error: \(error)")
            return nil
        }
    }

    /// Recover address from EIP-712 typed data signature using secp256k1
    /// - Parameters:
    ///   - signature: Signature string (with or without 0x prefix)
    ///   - typedData: EIP-712 typed data that was signed
    /// - Returns: Recovered address or nil if recovery fails
    public func recoverAddressFromTypedData(signature: String, typedData: EIP712TypedData) -> String? {
        do {
            let cleanSignature = signature.replacingOccurrences(of: "0x", with: "")
            let sigData = Data(hexString: cleanSignature)
            guard sigData.count == 65 else {
                return nil
            }

            // Hash the typed data
            let digest = hashTypedData(typedData)

            // Recover public key using web3swift
            guard let recoveredPublicKey = try SECP256K1.recoverPublicKey(
                hash: digest,
                signature: sigData
            ) else {
                return nil
            }

            // Get Ethereum address from public key (remove first byte 0x04)
            let publicKeyData = recoveredPublicKey.dropFirst()
            let addressData = publicKeyData.sha3(.keccak256).suffix(20)
            let recoveredAddress = "0x" + addressData.toHexString()

            return recoveredAddress
        } catch {
            return nil
        }
    }

    /// Hash EIP-712 typed data using CryptoSwift
    /// - Parameter typedData: EIP-712 typed data to hash
    /// - Returns: Keccak256 hash of the typed data
    public func hashTypedData(_ typedData: EIP712TypedData) -> Data {
        do {
            let encoded = try JSONEncoder().encode(typedData)
            return keccak256(encoded)
        } catch {
            return Data()
        }
    }

    /// Hash message for personal_sign (with EIP-191 prefix) using CryptoSwift
    /// - Parameter message: Message to hash
    /// - Returns: Keccak256 hash of the prefixed message
    public func hashPersonalMessage(_ message: String) -> Data {
        let messageData = Data(message.utf8)
        let prefix = Data("\u{19}Ethereum Signed Message:\n\(messageData.count)".utf8)
        let fullMessage = prefix + messageData
        return keccak256(fullMessage)
    }

    /// Keccak256 hash function using CryptoSwift
    /// - Parameter data: Data to hash
    /// - Returns: Keccak256 hash
    public func keccak256(_ data: Data) -> Data {
        let digest = SHA3(variant: .keccak256)
        let hash = digest.calculate(for: [UInt8](data))
        return Data(hash)
    }

    // MARK: - Blockchain Utilities

    /// Create Blockchain object from namespace and reference
    /// - Parameters:
    ///   - namespace: Blockchain namespace (e.g., "eip155")
    ///   - reference: Chain reference (e.g., "1" for Ethereum mainnet)
    /// - Returns: Blockchain object or nil if invalid
    public func createBlockchain(namespace: String, reference: String) -> Blockchain? {
        return Blockchain(namespace: namespace, reference: reference)
    }

    /// Create Blockchain object from CAIP-2 string
    /// - Parameter chainId: CAIP-2 format string (e.g., "eip155:1")
    /// - Returns: Blockchain object or nil if invalid
    public func createBlockchain(chainId: String) -> Blockchain? {
        return Blockchain(chainId)
    }

    /// Create Blockchain object for Ethereum-compatible chain
    /// - Parameter chainId: Ethereum chain ID (e.g., "1", "137", "612055")
    /// - Returns: Blockchain object with eip155 namespace
    public func createEthereumBlockchain(chainId: String) -> Blockchain? {
        return Blockchain(namespace: "eip155", reference: chainId)
    }

    /// Get Blockchain object from CrossChain
    /// - Parameter chain: CrossChain enum value
    /// - Returns: Blockchain object for the chain
    public func getBlockchain(for chain: CrossChain) -> Blockchain? {
        return chain.blockchain
    }
}
