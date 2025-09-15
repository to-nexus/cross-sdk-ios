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

/// Errors that can occur in CrossUtils operations
public enum CrossUtilsError: LocalizedError {
    case invalidAddress(String)
    case invalidAmount(String)
    case conversionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAddress(let message):
            return "Invalid address: \(message)"
        case .invalidAmount(let message):
            return "Invalid amount: \(message)"
        case .conversionFailed(let message):
            return "Conversion failed: \(message)"
        }
    }
}

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
    
    // MARK: - Address Validation
    
    /// Validate Ethereum address format
    /// - Parameter address: Address string to validate
    /// - Returns: True if valid Ethereum address format
    public func isValidAddress(_ address: String) -> Bool {
        let pattern = "^0x[0-9a-fA-F]{40}$"
        return address.range(of: pattern, options: .regularExpression) != nil
    }
    
    // MARK: - Hex Number Conversion
    
    /// Convert hex string to Decimal
    /// - Parameter hex: Hex string (with or without 0x prefix)
    /// - Returns: Decimal representation of the hex value
    public func hexToDecimal(_ hex: String) -> Decimal {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        
        // 빈 문자열이거나 "0"인 경우
        if cleanHex.isEmpty || cleanHex == "0" {
            return Decimal(0)
        }
        
        // Hex를 decimal로 변환
        var decimal = Decimal(0)
        var multiplier = Decimal(1)
        
        for char in cleanHex.reversed() {
            if let digit = Int(String(char), radix: 16) {
                decimal += Decimal(digit) * multiplier
                multiplier *= 16
            } else {
                // 잘못된 hex 문자가 있으면 0 반환
                return Decimal(0)
            }
        }
        
        return decimal
    }
    
    /// Convert decimal string to hex string
    /// - Parameter decimal: Decimal string to convert
    /// - Returns: Hex string representation
    public func decimalStringToHex(_ decimal: String) -> String {
        let digitsOnly = decimal.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted)
        if digitsOnly == "" || digitsOnly == "0" { return "0" }
        var number = digitsOnly
        var hex = ""
        let hexAlphabet = Array("0123456789abcdef")
        while number != "0" {
            let (q, r) = divideDecimalStringBy16(number)
            hex.append(hexAlphabet[r])
            number = q
        }

        return String(hex.reversed())
    }
    
    /// Helper function to divide decimal string by 16
    /// - Parameter decimal: Decimal string to divide
    /// - Returns: Tuple of quotient and remainder
    private func divideDecimalStringBy16(_ decimal: String) -> (quotient: String, remainder: Int) {
        var carry = 0
        var quotient = ""
        for ch in decimal {
            let d = Int(String(ch)) ?? 0
            let value = carry * 10 + d
            let q = value / 16
            let r = value % 16
            if !(quotient.isEmpty && q == 0) { quotient.append(String(q)) }
            carry = r
        }
        if quotient.isEmpty { quotient = "0" }
        return (quotient, carry)
    }
    
    // MARK: - Smart Contract Data Encoding
    
    /// Encode ERC-20 transfer function call data
    /// - Parameters:
    ///   - to: Recipient address
    ///   - amount: Transfer amount as string
    ///   - decimals: Token decimals
    /// - Returns: Encoded function call data
    /// - Throws: CrossUtilsError if encoding fails
    public func encodeERC20TransferData(to: String, amount: String, decimals: Int) throws -> String {
        let selector = "a9059cbb"
        let addressNoPrefix = String(to.dropFirst(2)).lowercased()
        guard addressNoPrefix.count == 40 else { 
            throw CrossUtilsError.invalidAddress("수신자 주소 형식이 올바르지 않습니다") 
        }

        let amountHex = try amountToUInt256Hex(amount, decimals: decimals)
        let paddedAddress = addressNoPrefix.leftPadded(to: 64)
        let paddedAmount = amountHex.leftPadded(to: 64)
        return "0x" + selector + paddedAddress + paddedAmount
    }
    
    /// Convert amount string to uint256 hex representation
    /// - Parameters:
    ///   - amount: Amount as decimal string
    ///   - decimals: Number of decimal places
    /// - Returns: Hex representation of the amount
    /// - Throws: CrossUtilsError if conversion fails
    public func amountToUInt256Hex(_ amount: String, decimals: Int) throws -> String {
        let s = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^\\d*(?:\\.\\d*)?$"
        guard s.range(of: pattern, options: .regularExpression) != nil, !s.isEmpty else {
            throw CrossUtilsError.invalidAmount("금액 형식이 올바르지 않습니다")
        }

        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        let intPart = parts.first.map(String.init) ?? "0"
        let fracPart = parts.count > 1 ? String(parts[1]) : ""
        if fracPart.count > decimals { 
            throw CrossUtilsError.invalidAmount("소수 자릿수가 너무 큽니다") 
        }
        let paddedFrac = fracPart + String(repeating: "0", count: max(0, decimals - fracPart.count))

        // 결합된 10진 정수 문자열 (앞의 0 제거)
        let combined = (intPart + paddedFrac).drop { $0 == "0" }
        let decimalString = combined.isEmpty ? "0" : String(combined)

        // 10진 문자열 → 16진 문자열로 변환
        return decimalStringToHex(decimalString)
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

    /// Hash EIP-712 typed data according to EIP-712 standard
    /// - Parameter typedData: EIP-712 typed data to hash
    /// - Returns: Keccak256 hash of the typed data according to EIP-712 standard
    public func hashTypedData(_ typedData: EIP712TypedData) -> Data {
        do {
            // EIP-712 standard: keccak256("\x19\x01" ‖ domainSeparator ‖ hashStruct(message))
            
            // 1. Calculate domain separator hash
            let domainSeparator = hashDomain(typedData.domain, types: typedData.types)
            
            // 2. Calculate message hash
            let messageHash = hashStruct(typedData.primaryType, data: typedData.message, types: typedData.types)
            
            // 3. Combine with EIP-712 prefix
            var finalData = Data([0x19, 0x01]) // "\x19\x01"
            finalData.append(domainSeparator)
            finalData.append(messageHash)
            
            return keccak256(finalData)
        } catch {
            print("❌ EIP-712 hash calculation error: \(error)")
            return Data()
        }
    }
    
    /// Hash EIP-712 domain separator
    internal func hashDomain(_ domain: EIP712Domain, types: [String: [EIP712Type]]) -> Data {
        // EIP712Domain type definition
        let domainType = "EIP712Domain"
        
        // Create domain data dictionary
        var domainData: [String: AnyCodable] = [:]
        if let name = domain.name { domainData["name"] = AnyCodable(name) }
        if let version = domain.version { domainData["version"] = AnyCodable(version) }
        if let chainId = domain.chainId { domainData["chainId"] = AnyCodable(chainId) }
        if let verifyingContract = domain.verifyingContract { domainData["verifyingContract"] = AnyCodable(verifyingContract) }
        if let salt = domain.salt { domainData["salt"] = AnyCodable(salt) }
        
        
        // EIP712Domain 타입이 types에 없으면 추가
        var updatedTypes = types
        if updatedTypes["EIP712Domain"] == nil {
            var domainFields: [EIP712Type] = []
            if domain.name != nil { domainFields.append(EIP712Type(name: "name", type: "string")) }
            if domain.version != nil { domainFields.append(EIP712Type(name: "version", type: "string")) }
            if domain.chainId != nil { domainFields.append(EIP712Type(name: "chainId", type: "uint256")) }
            if domain.verifyingContract != nil { domainFields.append(EIP712Type(name: "verifyingContract", type: "address")) }
            if domain.salt != nil { domainFields.append(EIP712Type(name: "salt", type: "bytes32")) }
            updatedTypes["EIP712Domain"] = domainFields
        }
        
        return hashStruct(domainType, data: domainData, types: updatedTypes)
    }
    
    /// Hash a struct according to EIP-712
    internal func hashStruct(_ primaryType: String, data: [String: AnyCodable], types: [String: [EIP712Type]]) -> Data {
        let typeHash = hashType(primaryType, types: types)
        let encodedData = encodeData(primaryType, data: data, types: types)
        
        var combined = Data()
        combined.append(typeHash)
        combined.append(encodedData)
        
        return keccak256(combined)
    }
    
    /// Generate type hash for EIP-712
    private func hashType(_ primaryType: String, types: [String: [EIP712Type]]) -> Data {
        let typeString = encodeType(primaryType, types: types)
        return keccak256(typeString.data(using: .utf8) ?? Data())
    }
    
    /// Encode type string for EIP-712
    internal func encodeType(_ primaryType: String, types: [String: [EIP712Type]]) -> String {
        var deps = findDependencies(primaryType, types: types)
        deps = deps.filter { $0 != primaryType }
        deps.sort()
        deps.insert(primaryType, at: 0)
        
        var result = ""
        for dep in deps {
            if let typeFields = types[dep] {
                result += "\(dep)("
                result += typeFields.map { "\($0.type) \($0.name)" }.joined(separator: ",")
                result += ")"
            }
        }
        
        return result
    }
    
    /// Find dependencies for a type
    private func findDependencies(_ primaryType: String, types: [String: [EIP712Type]]) -> [String] {
        var deps = Set<String>()
        
        func findDeps(_ type: String) {
            if deps.contains(type) { return }
            deps.insert(type)
            
            if let typeFields = types[type] {
                for field in typeFields {
                    let baseType = field.type.components(separatedBy: "[")[0] // Remove array notation
                    if types.keys.contains(baseType) {
                        findDeps(baseType)
                    }
                }
            }
        }
        
        findDeps(primaryType)
        return Array(deps)
    }
    
    /// Encode data according to EIP-712
    private func encodeData(_ primaryType: String, data: [String: AnyCodable], types: [String: [EIP712Type]]) -> Data {
        guard let typeFields = types[primaryType] else { return Data() }
        
        var encoded = Data()
        
        for field in typeFields {
            if let value = data[field.name] {
                let encodedValue = encodeValue(field.type, value: value, types: types)
                encoded.append(encodedValue)
            } else {
                // Pad with zeros for missing fields
                encoded.append(Data(repeating: 0, count: 32))
            }
        }
        
        return encoded
    }
    
    /// Encode a single value according to EIP-712
    private func encodeValue(_ type: String, value: AnyCodable, types: [String: [EIP712Type]]) -> Data {
        // Handle arrays
        if type.hasSuffix("]") {
            // Array type - simplified handling
            return keccak256(Data()) // Placeholder for array handling
        }
        
        // Handle custom types
        if types.keys.contains(type) {
            if let dict = value.value as? [String: AnyCodable] {
                return hashStruct(type, data: dict, types: types)
            }
            return Data(repeating: 0, count: 32)
        }
        
        // Handle primitive types
        switch type {
        case "address":
            if let addr = value.value as? String {
                let cleanAddr = addr.replacingOccurrences(of: "0x", with: "").lowercased()
                let addrData = Data(hexString: cleanAddr)
                if addrData.count == 20 { // Valid Ethereum address
                    return Data(repeating: 0, count: 12) + addrData // Pad to 32 bytes
                }
            }
            return Data(repeating: 0, count: 32)
            
        case "uint256", "int256":
            if let num = value.value as? Int {
                return encodeUInt256(UInt64(num))
            } else if let str = value.value as? String, let num = UInt64(str) {
                return encodeUInt256(num)
            }
            return Data(repeating: 0, count: 32)
            
        case "string":
            if let str = value.value as? String {
                return keccak256(str.data(using: .utf8) ?? Data())
            }
            return Data(repeating: 0, count: 32)
            
        case "bytes":
            if let hex = value.value as? String {
                let cleanHex = hex.replacingOccurrences(of: "0x", with: "")
                let data = Data(hexString: cleanHex)
                return keccak256(data)
            }
            return Data(repeating: 0, count: 32)
            
        default:
            return Data(repeating: 0, count: 32)
        }
    }
    
    /// Encode UInt256 to 32 bytes
    private func encodeUInt256(_ value: UInt64) -> Data {
        var data = Data(repeating: 0, count: 32)
        let valueBytes = withUnsafeBytes(of: value.bigEndian) { Data($0) }
        data.replaceSubrange((32-valueBytes.count)..<32, with: valueBytes)
        return data
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

    /// Create Blockchain object for Ethereum-compatible Unchain
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

// MARK: - String Extensions

private extension String {
    /// Left pad string with specified character
    /// - Parameters:
    ///   - length: Target length
    ///   - char: Character to pad with (default: "0")
    /// - Returns: Left-padded string
    func leftPadded(to length: Int, with char: Character = "0") -> String {
        if count >= length { return self }
        return String(repeating: String(char), count: length - count) + self
    }
}
