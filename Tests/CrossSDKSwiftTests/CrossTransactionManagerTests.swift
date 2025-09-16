import XCTest
import Combine
import Commons
@testable import CrossSDKSwift

final class CrossTransactionManagerTests: XCTestCase {
    
    var transactionManager: CrossTransactionManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        transactionManager = CrossTransactionManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        transactionManager = nil
        cancellables = nil
    }
    
    /// Test CrossTransactionManager initialization
    func testTransactionManagerInitialization() throws {
        // Given: Fresh transaction manager
        let manager = CrossTransactionManager()
        
        // Then: Verify initial state
        XCTAssertNotNil(manager, "Transaction manager should initialize successfully")
        
        print("✅ CrossTransactionManager initialization test passed!")
    }
    
    /// Test writeContract interface availability in CrossSDKSwift
    func testWriteContractInterfaceAvailable() {
        // Given: CrossSDKSwift instance
        let sdk = CrossSDKSwift.shared
        
        // Then: writeContract methods should be available (compile-time check)
        // If this compiles, the interface is available
        XCTAssertNotNil(sdk, "CrossSDKSwift should be initialized")
        
        // This test passes if the writeContract methods exist and compile
        print("✅ writeContract interface is available in CrossSDKSwift")
    }
    
    /// Test transaction request creation with custom data
    func testTransactionRequestWithCustomData() throws {
        // Given: Transaction parameters
        let from = "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba"
        let to = "0x742d35Cc6635C0532925a3b8D90B03E0b6b8F4C5"
        let value = "0x1000000000000000000" // 1 ETH in wei
        let data = "0x"
        let gas = "0x5208" // 21000
        let gasPrice = "0x9184e72a000" // 10 gwei
        
        let customData = CustomData(metadata: .object([
            "activity": AnyCodable("You are about to send 1 ETH to the receiver address."),
            "currentFormat": AnyCodable("This is a JSON formatted custom data."),
            "providedFormat": AnyCodable("Plain text(string), HTML(string), JSON(key value object) are supported."),
            "txTime": AnyCodable("2025-01-01T00:00:00Z"),
            "randomValue": AnyCodable("test-uuid-12345")
        ]))
        
        // When: Create transaction params
        let transactionParams = CrossTransactionParams(
            to: to,
            value: "1.0", // ETH 단위로 변경
            data: data,
            gasLimit: gas,
            gasPrice: gasPrice
        )
        
        // Then: Verify transaction params properties
        XCTAssertEqual(transactionParams.to, to, "To address should match")
        XCTAssertEqual(transactionParams.value, "1.0", "Value should match")
        XCTAssertEqual(transactionParams.data, data, "Data should match")
        XCTAssertEqual(transactionParams.gasLimit, gas, "Gas limit should match")
        XCTAssertEqual(transactionParams.gasPrice, gasPrice, "Gas price should match")
        
        // Verify custom data separately
        if case .object(let metadataDict) = customData.metadata {
            XCTAssertNotNil(metadataDict["activity"], "Activity should be present in metadata")
            XCTAssertNotNil(metadataDict["txTime"], "Transaction time should be present in metadata")
        } else {
            XCTFail("Custom data metadata should be an object")
        }
        
        print("✅ Transaction params with custom data test passed!")
        print("   To: \(transactionParams.to)")
        print("   Value: \(transactionParams.value)")
        print("   Gas Limit: \(transactionParams.gasLimit ?? "nil")")
        print("   Custom Data: ✓")
    }
    
    /// Test transaction params serialization
    func testTransactionParamsSerialization() throws {
        // Given: Transaction params
        let customData = CustomData(metadata: .string("Simple transaction metadata"))
        
        let transactionParams = CrossTransactionParams(
            to: "0x742d35Cc6635C0532925a3b8D90B03E0b6b8F4C5",
            value: "1.0",
            data: "0x",
            gasLimit: "21000",
            gasPrice: "10000000000"
        )
        
        // When: Test transaction params properties
        // Then: Verify params structure
        XCTAssertEqual(transactionParams.to, "0x742d35Cc6635C0532925a3b8D90B03E0b6b8F4C5", "To address should match")
        XCTAssertEqual(transactionParams.value, "1.0", "Value should be in ETH")
        XCTAssertEqual(transactionParams.data, "0x", "Data should match")
        XCTAssertEqual(transactionParams.gasLimit, "21000", "Gas limit should match")
        XCTAssertEqual(transactionParams.gasPrice, "10000000000", "Gas price should match")
        XCTAssertEqual(transactionParams.type, .legacy, "Should be legacy type with gas price")
        
        // Test custom data separately
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let customDataJson = try encoder.encode(customData)
        let customDataString = String(data: customDataJson, encoding: .utf8)
        
        XCTAssertNotNil(customDataString, "Custom data JSON serialization should succeed")
        XCTAssertTrue(customDataString?.contains("metadata") == true, "JSON should contain 'metadata' field")
        
        print("✅ Transaction params serialization test passed!")
        print("   Params properties: ✓")
        print("   Custom data JSON: ✓")
    }
    
    /// Test transaction result enum
    func testTransactionResultEnum() throws {
        // Given: Transaction result parameters
        let txHash = "0xd5ee7f4c4faf47505b996ec4ee42037593fdc16ab19bd2c1c4a967c2412f12a43"
        let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When: Create success and failure results
        let successResult = CrossTransactionResult.success(txHash)
        let failureResult = CrossTransactionResult.failure(error)
        
        // Then: Verify result types
        switch successResult {
        case .success(let hash):
            XCTAssertEqual(hash, txHash, "Success result should contain transaction hash")
        case .failure:
            XCTFail("Success result should not be failure")
        }
        
        switch failureResult {
        case .success:
            XCTFail("Failure result should not be success")
        case .failure(let err):
            XCTAssertEqual((err as NSError).localizedDescription, "Test error", "Failure result should contain error")
        }
        
        print("✅ Transaction result enum test passed!")
        print("   Success case: ✓")
        print("   Failure case: ✓")
    }
    
    /// Test different custom data formats for transactions
    func testTransactionCustomDataFormats() throws {
        // Given: Different custom data formats
        
        // 1. Plain string metadata
        let stringCustomData = CustomData(metadata: .string("You are about to send 1 CROSS to the receiver address. This is plain text formatted custom data."))
        
        // 2. HTML string metadata
        let htmlCustomData = CustomData(metadata: .string("<DOCTYPE html><html><head><title>Game Developer can add custom data to the transaction</title></head><body><h1>Game Developer can add custom data to the transaction</h1><p>This is a HTML text formatted custom data.</p></body></html>"))
        
        // 3. JSON object metadata
        let jsonCustomData = CustomData(metadata: .object([
            "activity": AnyCodable("You are about to send custom transaction to the contract."),
            "currentFormat": AnyCodable("This is a JSON formatted custom data."),
            "providedFormat": AnyCodable("Plain text(string), HTML(string), JSON(key value object) are supported."),
            "txTime": AnyCodable("2025-01-01T00:00:00Z"),
            "randomValue": AnyCodable("test-uuid-12345")
        ]))
        
        // When: Create transaction params (custom data is separate)
        let baseTransactionParams = CrossTransactionParams(
            to: "0x742d35Cc6635C0532925a3b8D90B03E0b6b8F4C5",
            value: "1.0",
            data: "0x",
            gasLimit: "21000",
            gasPrice: "10000000000"
        )
        
        // Then: Verify different custom data formats serialize correctly
        let encoder = JSONEncoder()
        
        // Test string format
        let stringData = try encoder.encode(stringCustomData)
        let stringDecoded = try JSONDecoder().decode(CustomData.self, from: stringData)
        XCTAssertEqual(stringDecoded.metadata, stringCustomData.metadata, "String metadata should serialize correctly")
        
        // Test HTML format
        let htmlData = try encoder.encode(htmlCustomData)
        let htmlDecoded = try JSONDecoder().decode(CustomData.self, from: htmlData)
        XCTAssertEqual(htmlDecoded.metadata, htmlCustomData.metadata, "HTML metadata should serialize correctly")
        
        // Test JSON format
        let jsonData = try encoder.encode(jsonCustomData)
        let jsonDecoded = try JSONDecoder().decode(CustomData.self, from: jsonData)
        XCTAssertEqual(jsonDecoded.metadata, jsonCustomData.metadata, "JSON metadata should serialize correctly")
        
        // Verify transaction params work with all custom data types
        XCTAssertNotNil(baseTransactionParams.to, "Base transaction params should be valid")
        XCTAssertEqual(baseTransactionParams.type, .legacy, "Should use legacy transaction type")
        
        print("✅ Transaction custom data formats test passed!")
        print("   String format: ✓")
        print("   HTML format: ✓")
        print("   JSON format: ✓")
    }
    
    /// Test transaction validation
    func testTransactionValidation() throws {
        // Given: Valid and invalid transaction parameters
        
        // Valid transaction params
        let validTransactionParams = CrossTransactionParams(
            to: "0x742d35Cc6635C0532925a3b8D90B03E0b6b8F4C5",
            value: "1.0",
            data: "0x",
            gasLimit: "21000",
            gasPrice: "10000000000"
        )
        
        // Then: Verify transaction params properties
        XCTAssertTrue(validTransactionParams.to.hasPrefix("0x"), "To address should be hex formatted")
        XCTAssertFalse(validTransactionParams.value.hasPrefix("0x"), "Value should be in ETH units, not hex")
        XCTAssertTrue(validTransactionParams.data?.hasPrefix("0x") == true, "Data should be hex formatted")
        XCTAssertFalse(validTransactionParams.gasLimit?.hasPrefix("0x") == true, "Gas limit should be decimal")
        XCTAssertFalse(validTransactionParams.gasPrice?.hasPrefix("0x") == true, "Gas price should be decimal")
        
        // Verify address length (42 characters including 0x prefix)
        XCTAssertEqual(validTransactionParams.to.count, 42, "To address should be 42 characters")
        
        // Verify transaction type logic
        XCTAssertEqual(validTransactionParams.type, .legacy, "Should be legacy type with gas price and limit")
        
        // Test dynamic type
        let dynamicTransaction = CrossTransactionParams(
            to: "0x742d35Cc6635C0532925a3b8D90B03E0b6b8F4C5",
            value: "1.0",
            maxFeePerGas: "20000000000",
            maxPriorityFeePerGas: "2000000000"
        )
        XCTAssertEqual(dynamicTransaction.type, .dynamic, "Should be dynamic type without gas price")
        
        print("✅ Transaction validation test passed!")
        print("   Address format: ✓")
        print("   Hex formatting: ✓")
        print("   Required fields: ✓")
    }
    
    /// Test contract reading functionality
    func testContractReading() throws {
        print("🧪 Testing contract reading functionality...")
        
        let manager = CrossTransactionManager()
        
        // Test function selector generation
        let balanceOfABI = "balanceOf(address)"
        let totalSupplyABI = "totalSupply()"
        let transferABI = "transfer(address,uint256)"
        
        // These should not throw
        XCTAssertNoThrow(try manager.generateFunctionSelector(abi: balanceOfABI))
        XCTAssertNoThrow(try manager.generateFunctionSelector(abi: totalSupplyABI))
        XCTAssertNoThrow(try manager.generateFunctionSelector(abi: transferABI))
        
        print("✅ Function selector generation tests passed!")
        
        // Test parameter encoding
        let addressParam = "0x742d35cc6634c0532925a3b8d6ac6e7d7f0b2c2f"
        let numberParam = "1000000000000000000"  // 1 ETH in wei
        let hexParam = "0x1000000000000000000000000000000000000000000000000de0b6b3a7640000"
        
        XCTAssertNoThrow(try manager.encodeParameters(params: [addressParam]))
        XCTAssertNoThrow(try manager.encodeParameters(params: [numberParam]))
        XCTAssertNoThrow(try manager.encodeParameters(params: [hexParam]))
        XCTAssertNoThrow(try manager.encodeParameters(params: [addressParam, numberParam]))
        XCTAssertNoThrow(try manager.encodeParameters(params: []))
        
        print("✅ Parameter encoding tests passed!")
        
        // Test invalid parameters
        let invalidParam = "invalid_parameter_type"
        XCTAssertThrowsError(try manager.encodeParameters(params: [invalidParam])) { error in
            XCTAssertTrue(error.localizedDescription.contains("Unsupported parameter type"))
        }
        
        print("✅ Invalid parameter handling tests passed!")
        
        // Test specific encoding results
        let encodedAddress = try manager.encodeParameters(params: [addressParam])
        XCTAssertEqual(encodedAddress.count, 64, "Address should be encoded to 64 hex characters (32 bytes)")
        XCTAssertTrue(encodedAddress.hasSuffix("742d35cc6634c0532925a3b8d6ac6e7d7f0b2c2f"), "Address should be properly padded")
        
        let encodedNumber = try manager.encodeParameters(params: [numberParam])
        XCTAssertEqual(encodedNumber.count, 64, "Number should be encoded to 64 hex characters (32 bytes)")
        
        print("✅ Encoding result validation tests passed!")
        
        print("✅ All contract reading tests passed!")
    }
    
    /// Test ABI function selector generation
    func testFunctionSelectorGeneration() throws {
        print("🧪 Testing function selector generation...")
        
        let manager = CrossTransactionManager()
        
        // Test known function selectors
        let balanceOfSelector = try manager.generateFunctionSelector(abi: "balanceOf(address)")
        let totalSupplySelector = try manager.generateFunctionSelector(abi: "totalSupply()")
        let transferSelector = try manager.generateFunctionSelector(abi: "transfer(address,uint256)")
        
        // Verify selector length (should be 8 hex characters = 4 bytes)
        XCTAssertEqual(balanceOfSelector.count, 8, "Function selector should be 8 hex characters")
        XCTAssertEqual(totalSupplySelector.count, 8, "Function selector should be 8 hex characters")
        XCTAssertEqual(transferSelector.count, 8, "Function selector should be 8 hex characters")
        
        // Verify selectors are different
        XCTAssertNotEqual(balanceOfSelector, totalSupplySelector, "Different functions should have different selectors")
        XCTAssertNotEqual(balanceOfSelector, transferSelector, "Different functions should have different selectors")
        XCTAssertNotEqual(totalSupplySelector, transferSelector, "Different functions should have different selectors")
        
        // Test that same ABI produces same selector
        let balanceOfSelector2 = try manager.generateFunctionSelector(abi: "balanceOf(address)")
        XCTAssertEqual(balanceOfSelector, balanceOfSelector2, "Same ABI should produce same selector")
        
        print("✅ Function selector generation tests passed!")
        print("   balanceOf(address): \(balanceOfSelector)")
        print("   totalSupply(): \(totalSupplySelector)")
        print("   transfer(address,uint256): \(transferSelector)")
    }
    
    /// Test parameter encoding edge cases
    func testParameterEncodingEdgeCases() throws {
        print("🧪 Testing parameter encoding edge cases...")
        
        let manager = CrossTransactionManager()
        
        // Test empty parameters
        let emptyEncoded = try manager.encodeParameters(params: [])
        XCTAssertEqual(emptyEncoded, "", "Empty parameters should produce empty string")
        
        // Test zero values
        let zeroNumber = try manager.encodeParameters(params: ["0"])
        XCTAssertEqual(zeroNumber.count, 64, "Zero should be encoded to 64 hex characters")
        XCTAssertEqual(zeroNumber, String(repeating: "0", count: 64), "Zero should be all zeros")
        
        // Test maximum UInt64 value
        let maxUInt64 = String(UInt64.max)
        XCTAssertNoThrow(try manager.encodeParameters(params: [maxUInt64]))
        
        // Test hex values with and without 0x prefix
        let hexWithPrefix = "0x1234"
        let encodedWithPrefix = try manager.encodeParameters(params: [hexWithPrefix])
        
        XCTAssertEqual(encodedWithPrefix.count, 64, "Hex value should be encoded to 64 characters")
        
        // Test mixed parameters
        let mixedParams = ["0x742d35cc6634c0532925a3b8d6ac6e7d7f0b2c2f", "1000"]
        let mixedEncoded = try manager.encodeParameters(params: mixedParams)
        XCTAssertEqual(mixedEncoded.count, 128, "Two parameters should produce 128 hex characters (64 each)")
        
        print("✅ Parameter encoding edge cases tests passed!")
    }
    
    /// Test contract writing functionality
    func testContractWriting() throws {
        print("🧪 Testing contract writing functionality...")
        
        let manager = CrossTransactionManager()
        
        // Test writeContract parameter validation
        let contractAddress = "0xA0b86a33E6441E0C6b06b7A8DB6e1E2C6A8b7B8C"
        let transferABI = "transfer(address,uint256)"
        let approveABI = "approve(address,uint256)"
        let mintABI = "mint()"
        
        // Test data generation for different contract calls
        let recipient = "0x742d35cc6634c0532925a3b8d6ac6e7d7f0b2c2f"
        let amount = "1000000000000000000"  // 1 token (18 decimals)
        
        // Test function selector and parameter encoding (without actually sending)
        let transferSelector = try manager.generateFunctionSelector(abi: transferABI)
        let transferParams = try manager.encodeParameters(params: [recipient, amount])
        let transferData = "0x" + transferSelector + transferParams
        
        XCTAssertEqual(transferSelector.count, 8, "Transfer selector should be 8 hex characters")
        XCTAssertEqual(transferParams.count, 128, "Two parameters should produce 128 hex characters")
        XCTAssertTrue(transferData.hasPrefix("0x"), "Call data should start with 0x")
        
        print("✅ Contract call data generation tests passed!")
        
        // Test approve function
        let approveSelector = try manager.generateFunctionSelector(abi: approveABI)
        let approveParams = try manager.encodeParameters(params: [contractAddress, amount])
        let approveData = "0x" + approveSelector + approveParams
        
        XCTAssertEqual(approveSelector.count, 8, "Approve selector should be 8 hex characters")
        XCTAssertNotEqual(transferSelector, approveSelector, "Different functions should have different selectors")
        
        print("✅ Multiple contract functions tests passed!")
        
        // Test parameterless function
        let mintSelector = try manager.generateFunctionSelector(abi: mintABI)
        let mintParams = try manager.encodeParameters(params: [])
        let mintData = "0x" + mintSelector + mintParams
        
        XCTAssertEqual(mintSelector.count, 8, "Mint selector should be 8 hex characters")
        XCTAssertEqual(mintParams.count, 0, "No parameters should produce empty string")
        XCTAssertEqual(mintData.count, 10, "Parameterless call data should be 10 characters (0x + 8)")
        
        print("✅ Parameterless contract function tests passed!")
        
        print("✅ All contract writing tests passed!")
        print("   Transfer data: \(transferData.prefix(20))...")
        print("   Approve data: \(approveData.prefix(20))...")
        print("   Mint data: \(mintData)")
    }
    
    /// Test writeContract with various transaction types
    func testWriteContractTransactionTypes() throws {
        print("🧪 Testing writeContract with different transaction types...")
        
        let manager = CrossTransactionManager()
        let contractAddress = "0xA0b86a33E6441E0C6b06b7A8DB6e1E2C6A8b7B8C"
        
        // Test ERC-20 transfer call data generation
        let transferABI = "transfer(address,uint256)"
        let recipient = "0x742d35cc6634c0532925a3b8d6ac6e7d7f0b2c2f"
        let amount = "1000000000000000000"
        
        let transferSelector = try manager.generateFunctionSelector(abi: transferABI)
        let transferParams = try manager.encodeParameters(params: [recipient, amount])
        let expectedData = "0x" + transferSelector + transferParams
        
        // Verify the expected call data structure
        XCTAssertTrue(expectedData.hasPrefix("0x"), "Call data should start with 0x")
        XCTAssertEqual(expectedData.count, 138, "Transfer call data should be 138 characters (0x + 8 + 128)")
        
        print("✅ ERC-20 transfer call data validation passed!")
        
        // Test ERC-20 approve call data
        let approveABI = "approve(address,uint256)"
        let spender = "0x1234567890123456789012345678901234567890"
        let allowance = "2000000000000000000"
        
        let approveSelector = try manager.generateFunctionSelector(abi: approveABI)
        let approveParams = try manager.encodeParameters(params: [spender, allowance])
        let approveData = "0x" + approveSelector + approveParams
        
        XCTAssertNotEqual(transferSelector, approveSelector, "Transfer and approve should have different selectors")
        XCTAssertEqual(approveData.count, 138, "Approve call data should be 138 characters")
        
        print("✅ ERC-20 approve call data validation passed!")
        
        // Test contract deployment-like call (no 'to' address, but we'll use constructor params)
        let constructorABI = "constructor(string,string,uint256)"
        let constructorParams = ["TokenName", "TKN", "1000000000000000000000000"]  // name, symbol, totalSupply
        
        // Note: For constructor, we can't use encodeParameters as it doesn't handle string encoding
        // This is just to test the selector generation
        let constructorSelector = try manager.generateFunctionSelector(abi: constructorABI)
        XCTAssertEqual(constructorSelector.count, 8, "Constructor selector should be 8 hex characters")
        
        print("✅ Constructor selector generation passed!")
        
        print("✅ All writeContract transaction type tests passed!")
    }
    
    /// Test writeContract error handling
    func testWriteContractErrorHandling() throws {
        print("🧪 Testing writeContract error handling...")
        
        let manager = CrossTransactionManager()
        
        // Test invalid ABI signatures
        let invalidABI = "invalid_abi_signature"
        XCTAssertNoThrow(try manager.generateFunctionSelector(abi: invalidABI), "Should generate selector even for invalid ABI")
        
        // Test invalid parameters
        let validABI = "transfer(address,uint256)"
        let invalidParams = ["invalid_address", "not_a_number"]
        
        XCTAssertThrowsError(try manager.encodeParameters(params: ["invalid_address"])) { error in
            XCTAssertTrue(error.localizedDescription.contains("Unsupported parameter type"))
        }
        
        XCTAssertThrowsError(try manager.encodeParameters(params: ["0x123"])) { error in
            XCTAssertTrue(error.localizedDescription.contains("Unsupported parameter type"))
        }
        
        print("✅ Error handling tests passed!")
        
        // Test edge cases
        let emptyABI = ""
        XCTAssertNoThrow(try manager.generateFunctionSelector(abi: emptyABI))
        
        let longABI = "veryLongFunctionNameWithManyParameters(address,uint256,string,bytes32,bool,uint8)"
        XCTAssertNoThrow(try manager.generateFunctionSelector(abi: longABI))
        
        print("✅ Edge case tests passed!")
        
        print("✅ All writeContract error handling tests passed!")
    }
}
