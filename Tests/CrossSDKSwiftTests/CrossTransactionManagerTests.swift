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
}
