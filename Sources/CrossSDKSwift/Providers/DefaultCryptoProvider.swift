//
//  DefaultCryptoProvider.swift
//  CrossSDKSwift
//
//  Created by CrossSDK Team
//

import Foundation
import web3swift
import Web3Core
import CryptoSwift
import WalletConnectSigner

/// Crypto-related errors
public enum CryptoError: Error {
    case publicKeyRecoveryFailed
    case invalidSignatureFormat
}

/// Default implementation of CryptoProvider using web3swift and CryptoSwift
public struct DefaultCryptoProvider: CryptoProvider {

    /// Recover public key from Ethereum signature
    /// - Parameters:
    ///   - signature: Ethereum signature
    ///   - message: Original message data
    /// - Returns: Recovered public key data
    /// - Throws: Error if recovery fails
    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        // Convert EthereumSignature to Data format
        var sigData = Data()
        let rData = Data(signature.r)
        let sData = Data(signature.s)
        
        // Ensure r and s are 32 bytes each
        let rPadded = Data(repeating: 0, count: max(0, 32 - rData.count)) + rData
        let sPadded = Data(repeating: 0, count: max(0, 32 - sData.count)) + sData
        
        sigData.append(rPadded)
        sigData.append(sPadded)
        sigData.append(UInt8(signature.v))
        
        // Recover public key using web3swift
        guard let publicKey = try SECP256K1.recoverPublicKey(
            hash: message,
            signature: sigData
        ) else {
            throw CryptoError.publicKeyRecoveryFailed
        }
        
        return publicKey
    }

    /// Calculate Keccak256 hash
    /// - Parameter data: Input data to hash
    /// - Returns: Keccak256 hash result
    public func keccak256(_ data: Data) -> Data {
        let digest = SHA3(variant: .keccak256)
        let hash = digest.calculate(for: [UInt8](data))
        return Data(hash)
    }

    /// Public initializer
    public init() {}
}
