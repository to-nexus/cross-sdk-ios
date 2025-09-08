import XCTest
import Combine
import Commons
@testable import CrossSDKSwift

final class CrossSigningManagerTests: XCTestCase {
    
    var signingManager: CrossSigningManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        signingManager = CrossSigningManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        signingManager = nil
        cancellables = nil
    }
    
    /// Test CrossSigningManager initialization
    func testSigningManagerInitialization() throws {
        // Given: Fresh signing manager
        let manager = CrossSigningManager()
        
        // Then: Verify initial state
        XCTAssertNotNil(manager, "Signing manager should initialize successfully")
        
        print("✅ CrossSigningManager initialization test passed!")
    }
    
    /// Test personal sign request creation
    func testPersonalSignRequestCreation() throws {
        // Given: Personal sign parameters
        let message = "Hello, Cross SDK!"
        let address = "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba"
        let customData = CustomData(metadata: .string("Test personal sign"))
        
        // When: Create personal sign request
        let request = CrossJSONRPC.personal_sign(
            address: address,
            message: message
        )
        
        let requestObject = CrossJSONRPCObject(jsonrpc: request, customData: customData)
        let (method, params) = requestObject.rawValues
        
        // Then: Verify request structure
        XCTAssertEqual(method, "personal_sign", "Method should be personal_sign")
        XCTAssertEqual(params.count, 3, "Should have 3 parameters")
        
        // Verify parameters
        if let hexMessage = params[0] as? String {
            XCTAssertTrue(hexMessage.hasPrefix("0x"), "Message should be hex encoded")
        } else {
            XCTFail("First parameter should be hex encoded message")
        }
        
        if let paramAddress = params[1] as? String {
            XCTAssertEqual(paramAddress, address, "Address should match")
        } else {
            XCTFail("Second parameter should be address")
        }
        
        if let customDataDict = params[2] as? [String: Any] {
            XCTAssertNotNil(customDataDict["metadata"], "Custom data should contain metadata")
        } else {
            XCTFail("Third parameter should be custom data dictionary")
        }
        
        print("✅ Personal sign request creation test passed!")
        print("   Method: \(method)")
        print("   Params count: \(params.count)")
    }
    
    /// Test eth sign request creation
    func testEthSignRequestCreation() throws {
        // Given: Eth sign parameters
        let address = "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba"
        let data = Data([0x48, 0x65, 0x6c, 0x6c, 0x6f]) // "Hello"
        let customData = CustomData(metadata: .object([
            "activity": AnyCodable("Eth sign test"),
            "timestamp": AnyCodable("2025-01-01T00:00:00Z")
        ]))
        
        // When: Create eth sign request
        let request = CrossJSONRPC.eth_sign(
            address: address,
            data: "0x" + data.toHexString()
        )
        
        let requestObject = CrossJSONRPCObject(jsonrpc: request, customData: customData)
        let (method, params) = requestObject.rawValues
        
        // Then: Verify request structure
        XCTAssertEqual(method, "eth_sign", "Method should be eth_sign")
        XCTAssertEqual(params.count, 3, "Should have 3 parameters")
        
        // Verify parameters
        if let paramAddress = params[0] as? String {
            XCTAssertEqual(paramAddress, address, "Address should match")
        } else {
            XCTFail("First parameter should be address")
        }
        
        if let hexData = params[1] as? String {
            XCTAssertTrue(hexData.hasPrefix("0x"), "Data should be hex encoded")
            XCTAssertEqual(hexData, "0x48656c6c6f", "Data should be correctly encoded")
        } else {
            XCTFail("Second parameter should be hex encoded data")
        }
        
        if let customDataDict = params[2] as? [String: Any] {
            XCTAssertNotNil(customDataDict["metadata"], "Custom data should contain metadata")
        } else {
            XCTFail("Third parameter should be custom data dictionary")
        }
        
        print("✅ Eth sign request creation test passed!")
        print("   Method: \(method)")
        print("   Params count: \(params.count)")
    }
    
    /// Test typed data request creation
    func testTypedDataRequestCreation() throws {
        // Given: Typed data parameters
        let types: [String: [EIP712Type]] = [
            "Person": [
                EIP712Type(name: "name", type: "string"),
                EIP712Type(name: "age", type: "uint256")
            ]
        ]
        
        let domain = EIP712Domain(
            name: "Test App",
            version: "1.0",
            chainId: 1,
            verifyingContract: "0x1234567890123456789012345678901234567890",
            salt: nil
        )
        
        let message: [String: AnyCodable] = [
            "name": AnyCodable("Alice"),
            "age": AnyCodable("30")
        ]
        
        let typedData = EIP712TypedData(
            types: types,
            primaryType: "Person",
            domain: domain,
            message: message
        )
        
        let address = "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba"
        let customData = CustomData(metadata: .string("Typed data test"))
        
        // When: Create typed data request
        let request = CrossJSONRPC.eth_signTypedData_v4(
            address: address,
            types: types,
            primaryType: "Person",
            domain: domain,
            message: message
        )
        let requestObject = CrossJSONRPCObject(jsonrpc: request, customData: customData)
        let (method, params) = requestObject.rawValues
        
        // Then: Verify request structure
        XCTAssertEqual(method, "eth_signTypedData_v4", "Method should be eth_signTypedData_v4")
        XCTAssertEqual(params.count, 2, "Should have 2 parameters")
        
        // Verify parameters
        if let typedDataDict = params[0] as? [String: Any] {
            XCTAssertNotNil(typedDataDict["types"], "Should contain types")
            XCTAssertNotNil(typedDataDict["domain"], "Should contain domain")
            XCTAssertNotNil(typedDataDict["message"], "Should contain message")
            XCTAssertNotNil(typedDataDict["address"], "Should contain address")
            XCTAssertEqual(typedDataDict["primaryType"] as? String, "Person", "Primary type should match")
        } else {
            XCTFail("First parameter should be typed data dictionary")
        }
        
        if let customDataDict = params[1] as? [String: Any] {
            XCTAssertNotNil(customDataDict["metadata"], "Custom data should contain metadata")
        } else {
            XCTFail("Second parameter should be custom data dictionary")
        }
        
        print("✅ Typed data request creation test passed!")
        print("   Method: \(method)")
        print("   Params count: \(params.count)")
    }
    
    /// Test CrossSigningResult creation
    func testCrossSigningResultCreation() throws {
        // Given: Signing result parameters
        let signature = "0xd5ee7f4c4faf47505b996ec4ee42037593fdc16ab19bd2c1c4a967c2412f12a43d13b7e3728b7e952977fd7be6127ba1bbdd3cc7dbea8589b7e9f4da6f9ce59e1b"
        let account = "0x3A0b00acB94f25ee85f33C4FA190804aaB08e2ba"
        
        let request = CrossJSONRPC.personal_sign(
            address: account,
            message: "Test message"
        )
        let requestObject = CrossJSONRPCObject(jsonrpc: request, customData: CustomData(metadata: .string("Test")))
        
        // When: Create signing result
        let result = CrossSigningResult(
            signature: signature,
            request: requestObject,
            account: account
        )
        
        // Then: Verify result properties
        XCTAssertEqual(result.signature, signature, "Signature should match")
        XCTAssertEqual(result.account, account, "Account should match")
        XCTAssertEqual(result.request.type, .personalSign, "Request type should match")
        XCTAssertNotNil(result.timestamp, "Timestamp should be set")
        
        // Verify timestamp is recent (within last minute)
        let timeDifference = Date().timeIntervalSince(result.timestamp)
        XCTAssertLessThan(timeDifference, 60, "Timestamp should be recent")
        
        print("✅ CrossSigningResult creation test passed!")
        print("   Signature: \(result.signature.prefix(20))...")
        print("   Account: \(result.account)")
        print("   Type: \(result.request.type.displayName)")
        print("   Timestamp: \(result.timestamp)")
    }
    
    /// Test request type extraction from CrossJSONRPCObject
    func testRequestTypeExtraction() throws {
        // Given: Different request types
        let personalSignRequest = CrossJSONRPCObject(
            jsonrpc: .personal_sign(address: "0x123", message: "test"),
            customData: CustomData(metadata: .string("test"))
        )
        
        let ethSignRequest = CrossJSONRPCObject(
            jsonrpc: .eth_sign(address: "0x123", data: "0x01"),
            customData: CustomData(metadata: .string("test"))
        )
        
        let types: [String: [EIP712Type]] = [
            "Test": [EIP712Type(name: "value", type: "string")]
        ]
        let domain = EIP712Domain(name: "Test", version: "1", chainId: 1, verifyingContract: "0x123", salt: nil)
        let message: [String: AnyCodable] = ["value": AnyCodable("test")]
        
        let typedDataRequest = CrossJSONRPCObject(
            jsonrpc: .eth_signTypedData_v4(
                address: "0x123",
                types: types,
                primaryType: "Test",
                domain: domain,
                message: message
            ),
            customData: CustomData(metadata: .string("test"))
        )
        
        // Then: Verify type extraction
        XCTAssertEqual(personalSignRequest.type, .personalSign, "Personal sign type should be extracted correctly")
        XCTAssertEqual(ethSignRequest.type, .ethSign, "Eth sign type should be extracted correctly")
        XCTAssertEqual(typedDataRequest.type, .ethSignTypedDataV4, "Typed data type should be extracted correctly")
        
        print("✅ Request type extraction test passed!")
        print("   Personal Sign: \(personalSignRequest.type.displayName)")
        print("   Eth Sign: \(ethSignRequest.type.displayName)")
        print("   Typed Data: \(typedDataRequest.type.displayName)")
    }
}
