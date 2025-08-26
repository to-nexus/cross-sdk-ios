//
//  DefaultCryptoProvider.swift
//  CrossSDKSwift
//
//  Created by CrossSDK Team
//

import Foundation
import Web3
import CryptoSwift
import WalletConnectSigner

/// Default implementation of CryptoProvider using Web3.swift and CryptoSwift
public struct DefaultCryptoProvider: CryptoProvider {

    /// Recover public key from Ethereum signature
    /// - Parameters:
    ///   - signature: Ethereum signature
    ///   - message: Original message data
    /// - Returns: Recovered public key data
    /// - Throws: Error if recovery fails
    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        let publicKey = try EthereumPublicKey(
            message: message.bytes,
            v: EthereumQuantity(quantity: BigUInt(signature.v)),
            r: EthereumQuantity(signature.r),
            s: EthereumQuantity(signature.s)
        )
        return Data(publicKey.rawPublicKey)
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
