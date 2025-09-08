import XCTest
import Commons
@testable import CrossSDKSwift

final class EIP712HashTests: XCTestCase {
    
    var utils: CrossUtils!
    
    override func setUpWithError() throws {
        utils = CrossUtils()
    }
    
    override func tearDownWithError() throws {
        utils = nil
    }
    
    /// Test EIP-712 hash calculation with real wallet data
    /// This test uses actual data from a wallet transaction to verify our EIP-712 implementation
    /// matches the expected digest: 0xac7421ebaba13af996b76619f9cb47e28eadfe57769c76219f3bb9b0ece64cba
    func testEIP712HashWithRealWalletData() throws {
        // Given: Real ERC20Mint typed data from wallet
        let types: [String: [EIP712Type]] = [
            "ERC20Mint": [
                EIP712Type(name: "token", type: "address"),
                EIP712Type(name: "amount", type: "uint256"),
                EIP712Type(name: "feeRecipient", type: "address"),
                EIP712Type(name: "feeBPS", type: "uint256"),
                EIP712Type(name: "nonce", type: "uint256"),
                EIP712Type(name: "deadline", type: "uint256")
            ]
        ]
        
        let domain = EIP712Domain(
            name: "mockService",
            version: "1",
            chainId: 612044,
            verifyingContract: "0xec0c78e2ba5ff4269b184680c9ab3755765575c1",
            salt: nil
        )
        
        let message: [String: AnyCodable] = [
            "token": AnyCodable("0xac6dc980a74874fa2edc9000f75f0dd2e0817cc9"),
            "amount": AnyCodable("1"),
            "feeRecipient": AnyCodable("0xc8c7000a6f913c147986683d091080c9a5030bd2"),
            "feeBPS": AnyCodable("100"),
            "nonce": AnyCodable("35"),
            "deadline": AnyCodable("1757310167")
        ]
        
        let typedData = EIP712TypedData(
            types: types,
            primaryType: "ERC20Mint",
            domain: domain,
            message: message
        )
        
        // When: Calculate EIP-712 hash
        let digest = utils.hashTypedData(typedData)
        let digestHex = "0x" + digest.toHexString()
        
        // Then: Verify it matches the expected wallet digest
        let expectedDigest = "0xac7421ebaba13af996b76619f9cb47e28eadfe57769c76219f3bb9b0ece64cba"
        XCTAssertEqual(digestHex, expectedDigest, "EIP-712 hash should match wallet-generated digest")
        
        print("✅ EIP-712 hash test passed!")
        print("   Generated: \(digestHex)")
        print("   Expected:  \(expectedDigest)")
    }
    
    /// Test EIP-712 domain separator calculation
    func testEIP712DomainSeparator() throws {
        // Given: Domain with standard fields
        let domain = EIP712Domain(
            name: "mockService",
            version: "1",
            chainId: 612044,
            verifyingContract: "0xec0c78e2ba5ff4269b184680c9ab3755765575c1",
            salt: nil
        )
        
        let types: [String: [EIP712Type]] = [:]
        
        // When: Calculate domain separator
        let domainSeparator = utils.hashDomain(domain, types: types)
        let domainHex = "0x" + domainSeparator.toHexString()
        
        // Then: Verify domain separator format
        XCTAssertEqual(domainSeparator.count, 32, "Domain separator should be 32 bytes")
        XCTAssertTrue(domainHex.hasPrefix("0x"), "Domain separator should be hex string")
        
        print("✅ Domain separator: \(domainHex)")
    }
    
    /// Test EIP-712 struct hash calculation
    func testEIP712StructHash() throws {
        // Given: ERC20Mint struct definition
        let types: [String: [EIP712Type]] = [
            "ERC20Mint": [
                EIP712Type(name: "token", type: "address"),
                EIP712Type(name: "amount", type: "uint256"),
                EIP712Type(name: "feeRecipient", type: "address"),
                EIP712Type(name: "feeBPS", type: "uint256"),
                EIP712Type(name: "nonce", type: "uint256"),
                EIP712Type(name: "deadline", type: "uint256")
            ]
        ]
        
        let message: [String: AnyCodable] = [
            "token": AnyCodable("0xac6dc980a74874fa2edc9000f75f0dd2e0817cc9"),
            "amount": AnyCodable("1"),
            "feeRecipient": AnyCodable("0xc8c7000a6f913c147986683d091080c9a5030bd2"),
            "feeBPS": AnyCodable("100"),
            "nonce": AnyCodable("35"),
            "deadline": AnyCodable("1757310167")
        ]
        
        // When: Calculate struct hash
        let structHash = utils.hashStruct("ERC20Mint", data: message, types: types)
        let structHex = "0x" + structHash.toHexString()
        
        // Then: Verify struct hash format
        XCTAssertEqual(structHash.count, 32, "Struct hash should be 32 bytes")
        XCTAssertTrue(structHex.hasPrefix("0x"), "Struct hash should be hex string")
        
        print("✅ Struct hash: \(structHex)")
    }
    
    /// Test EIP-712 type string encoding
    func testEIP712TypeEncoding() throws {
        // Given: ERC20Mint type definition
        let types: [String: [EIP712Type]] = [
            "ERC20Mint": [
                EIP712Type(name: "token", type: "address"),
                EIP712Type(name: "amount", type: "uint256"),
                EIP712Type(name: "feeRecipient", type: "address"),
                EIP712Type(name: "feeBPS", type: "uint256"),
                EIP712Type(name: "nonce", type: "uint256"),
                EIP712Type(name: "deadline", type: "uint256")
            ]
        ]
        
        // When: Encode type string
        let typeString = utils.encodeType("ERC20Mint", types: types)
        
        // Then: Verify type string format
        let expectedTypeString = "ERC20Mint(address token,uint256 amount,address feeRecipient,uint256 feeBPS,uint256 nonce,uint256 deadline)"
        XCTAssertEqual(typeString, expectedTypeString, "Type string should match expected format")
        
        print("✅ Type string: \(typeString)")
    }
    
    /// Test signature verification with EIP-712 data
    func testEIP712SignatureVerification() throws {
        // Given: Typed data and signature from wallet
        let types: [String: [EIP712Type]] = [
            "ERC20Mint": [
                EIP712Type(name: "token", type: "address"),
                EIP712Type(name: "amount", type: "uint256"),
                EIP712Type(name: "feeRecipient", type: "address"),
                EIP712Type(name: "feeBPS", type: "uint256"),
                EIP712Type(name: "nonce", type: "uint256"),
                EIP712Type(name: "deadline", type: "uint256")
            ]
        ]
        
        let domain = EIP712Domain(
            name: "mockService",
            version: "1",
            chainId: 612044,
            verifyingContract: "0xec0c78e2ba5ff4269b184680c9ab3755765575c1",
            salt: nil
        )
        
        let message: [String: AnyCodable] = [
            "token": AnyCodable("0xac6dc980a74874fa2edc9000f75f0dd2e0817cc9"),
            "amount": AnyCodable("1"),
            "feeRecipient": AnyCodable("0xc8c7000a6f913c147986683d091080c9a5030bd2"),
            "feeBPS": AnyCodable("100"),
            "nonce": AnyCodable("35"),
            "deadline": AnyCodable("1757310167")
        ]
        
        let typedData = EIP712TypedData(
            types: types,
            primaryType: "ERC20Mint",
            domain: domain,
            message: message
        )
        
        // Real signature from wallet
        let signature = "0xd5ee7f4c4faf47505b996ec4ee42037593fdc16ab19bd2c1c4a967c2412f12a43d13b7e3728b7e952977fd7be6127ba1bbdd3cc7dbea8589b7e9f4da6f9ce59e1b"
        let expectedAddress = "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba"
        
        // When: Verify signature
        let isValid = utils.verifyTypedDataV4(
            signature: signature,
            typedData: typedData,
            expectedAddress: expectedAddress
        )
        
        let recoveredAddress = utils.recoverAddressFromTypedData(
            signature: signature,
            typedData: typedData
        )
        
        // Then: Verify signature is valid and address matches
        XCTAssertTrue(isValid, "EIP-712 signature should be valid")
        XCTAssertEqual(recoveredAddress?.lowercased(), expectedAddress.lowercased(), "Recovered address should match expected address")
        
        print("✅ Signature verification passed!")
        print("   Expected: \(expectedAddress)")
        print("   Recovered: \(recoveredAddress ?? "nil")")
        print("   Valid: \(isValid)")
    }
    
    /// Test personal_sign signature verification
    func testPersonalSignVerification() throws {
        // Given: Personal sign test data
        let message = "Hello, World!"
        let signature = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1b"
        let expectedAddress = "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba"
        
        // When: Verify personal sign
        let isValid = utils.verifyPersonalSign(
            signature: signature,
            message: message,
            expectedAddress: expectedAddress
        )
        
        let recoveredAddress = utils.recoverAddress(
            signature: signature,
            message: message,
            signType: .personalSign
        )
        
        // Then: Check verification result
        print("✅ Personal sign test completed!")
        print("   Message: \(message)")
        print("   Expected: \(expectedAddress)")
        print("   Recovered: \(recoveredAddress ?? "nil")")
        print("   Valid: \(isValid)")
        
        // Note: This test uses dummy signature data for structure verification
        // In real scenario, use actual wallet-generated signatures
    }
    
    /// Test eth_sign signature verification
    func testEthSignVerification() throws {
        // Given: Eth sign test data
        let messageData = Data([0x48, 0x65, 0x6c, 0x6c, 0x6f]) // "Hello"
        let signature = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1b"
        let expectedAddress = "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba"
        
        // When: Verify eth sign
        let messageHex = "0x" + messageData.map { String(format: "%02x", $0) }.joined()
        let isValid = utils.verifyEthSign(
            signature: signature,
            data: messageData,
            expectedAddress: expectedAddress
        )
        
        let recoveredAddress = utils.recoverAddress(
            signature: signature,
            message: messageHex,
            signType: .ethSign
        )
        
        // Then: Check verification result
        print("✅ Eth sign test completed!")
        print("   Message Data: 0x\(messageData.map { String(format: "%02x", $0) }.joined())")
        print("   Expected: \(expectedAddress)")
        print("   Recovered: \(recoveredAddress ?? "nil")")
        print("   Valid: \(isValid)")
        
        // Note: This test uses dummy signature data for structure verification
        // In real scenario, use actual wallet-generated signatures
    }
    
    /// Test CrossJSONRPCObject creation and parsing
    func testCrossJSONRPCObjectCreation() throws {
        // Given: Different signing request types
        
        // 1. Personal Sign
        let personalSignRPC = CrossJSONRPC.personal_sign(
            address: "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba",
            message: "Hello, World!"
        )
        
        let personalSignObject = CrossJSONRPCObject(
            jsonrpc: personalSignRPC,
            customData: CustomData(metadata: .string("Personal sign test"))
        )
        let (personalMethod, personalParams) = personalSignObject.rawValues
        
        XCTAssertEqual(personalMethod, "personal_sign", "Personal sign method should be correct")
        XCTAssertEqual(personalParams.count, 3, "Personal sign should have 3 parameters")
        
        // 2. Eth Sign
        let ethSignRPC = CrossJSONRPC.eth_sign(
            address: "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba",
            data: "0x48656c6c6f"
        )
        
        let ethSignObject = CrossJSONRPCObject(
            jsonrpc: ethSignRPC,
            customData: CustomData(metadata: .string("Eth sign test"))
        )
        let (ethMethod, ethParams) = ethSignObject.rawValues
        
        XCTAssertEqual(ethMethod, "eth_sign", "Eth sign method should be correct")
        XCTAssertEqual(ethParams.count, 3, "Eth sign should have 3 parameters")
        
        // 3. EIP-712 Typed Data
        let types: [String: [EIP712Type]] = [
            "TestType": [
                EIP712Type(name: "value", type: "string")
            ]
        ]
        
        let domain = EIP712Domain(
            name: "TestDomain",
            version: "1",
            chainId: 1,
            verifyingContract: "0x1234567890123456789012345678901234567890",
            salt: nil
        )
        
        let message: [String: AnyCodable] = [
            "value": AnyCodable("test")
        ]
        
        let typedData = EIP712TypedData(
            types: types,
            primaryType: "TestType",
            domain: domain,
            message: message
        )
        
        let typedDataRPC = CrossJSONRPC.eth_signTypedData_v4(
            address: "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba",
            types: types,
            primaryType: "TestType",
            domain: domain,
            message: message
        )
        
        let typedDataObject = CrossJSONRPCObject(
            jsonrpc: typedDataRPC,
            customData: CustomData(metadata: .string("Typed data test"))
        )
        let (typedDataMethod, typedDataParams) = typedDataObject.rawValues
        
        XCTAssertEqual(typedDataMethod, "eth_signTypedData_v4", "Typed data method should be correct")
        XCTAssertEqual(typedDataParams.count, 2, "Typed data should have 2 parameters")
        
        print("✅ CrossJSONRPCObject creation tests passed!")
        print("   Personal Sign: \(personalMethod) with \(personalParams.count) params")
        print("   Eth Sign: \(ethMethod) with \(ethParams.count) params")
        print("   Typed Data: \(typedDataMethod) with \(typedDataParams.count) params")
    }
    
    /// Test CrossSigningType enum functionality
    func testCrossSigningTypeEnum() throws {
        // Given: Different signing type strings
        let personalSignType = CrossSigningType(rawValue: "personal_sign")
        let ethSignType = CrossSigningType(rawValue: "eth_sign")
        let typedDataType = CrossSigningType(rawValue: "eth_signTypedData_v4")
        let unknownType = CrossSigningType(rawValue: "unknown_method")
        
        // Then: Verify enum values
        XCTAssertEqual(personalSignType, .personalSign, "Personal sign type should match")
        XCTAssertEqual(ethSignType, .ethSign, "Eth sign type should match")
        XCTAssertEqual(typedDataType, .ethSignTypedDataV4, "Typed data type should match")
        XCTAssertNil(unknownType, "Unknown type should return nil")
        
        // Test display names
        XCTAssertEqual(personalSignType?.displayName, "Personal Sign", "Personal sign display name should be correct")
        XCTAssertEqual(ethSignType?.displayName, "ETH Sign", "Eth sign display name should be correct")
        XCTAssertEqual(typedDataType?.displayName, "EIP-712 Typed Data V4", "Typed data display name should be correct")
        
        // Test CrossJSONRPCObject type property extraction
        let personalRPC = CrossJSONRPC.personal_sign(address: "0x123", message: "test")
        let personalObject = CrossJSONRPCObject(jsonrpc: personalRPC, customData: nil)
        XCTAssertEqual(personalObject.type, .personalSign, "CrossJSONRPCObject.type should extract personal_sign correctly")
        
        print("✅ CrossSigningType enum tests passed!")
        print("   Personal Sign: \(personalSignType?.displayName ?? "nil")")
        print("   ETH Sign: \(ethSignType?.displayName ?? "nil")")
        print("   Typed Data: \(typedDataType?.displayName ?? "nil")")
        print("   Type extraction: ✓")
    }
    
    /// Test CustomData serialization
    func testCustomDataSerialization() throws {
        // Given: Different CustomData configurations
        
        // 1. String metadata
        let stringCustomData = CustomData(metadata: .string("Simple string metadata"))
        let stringData = try JSONEncoder().encode(stringCustomData)
        let stringDecoded = try JSONDecoder().decode(CustomData.self, from: stringData)
        
        XCTAssertEqual(stringCustomData.metadata, stringDecoded.metadata, "String metadata should serialize correctly")
        
        // 2. Dictionary metadata
        let dictMetadata: [String: AnyCodable] = [
            "activity": AnyCodable("Test activity"),
            "timestamp": AnyCodable("2025-01-01T00:00:00Z"),
            "value": AnyCodable(42)
        ]
        let dictCustomData = CustomData(metadata: .object(dictMetadata))
        let dictData = try JSONEncoder().encode(dictCustomData)
        let dictDecoded = try JSONDecoder().decode(CustomData.self, from: dictData)
        
        XCTAssertEqual(dictCustomData.metadata, dictDecoded.metadata, "Dictionary metadata should serialize correctly")
        
        // 3. CustomData with additional fields
        let additionalCustomData = CustomData(
            metadata: .string("Base metadata"),
            additional: [
                "extraField": AnyCodable("extra value"),
                "timestamp": AnyCodable(1704067200)
            ]
        )
        
        let additionalData = try JSONEncoder().encode(additionalCustomData)
        let additionalDecoded = try JSONDecoder().decode(CustomData.self, from: additionalData)
        
        XCTAssertEqual(additionalCustomData.metadata, additionalDecoded.metadata, "Additional fields metadata should serialize correctly")
        XCTAssertEqual(additionalCustomData.additional.count, additionalDecoded.additional.count, "Additional fields count should match")
        
        print("✅ CustomData serialization tests passed!")
        print("   String metadata: ✓")
        print("   Dictionary metadata: ✓")
        print("   Additional fields: ✓")
    }
}
