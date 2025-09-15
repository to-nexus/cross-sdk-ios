//
//  CrossUtilsTests.swift
//  CrossSDKSwiftTests
//
//  Created by Chuck on 9/10/25.
//

import XCTest
@testable import CrossSDKSwift

final class CrossUtilsTests: XCTestCase {
    
    var utils: CrossUtils!
    
    override func setUp() {
        super.setUp()
        utils = CrossUtils()
    }
    
    override func tearDown() {
        utils = nil
        super.tearDown()
    }
    
    // MARK: - Address Validation Tests
    
    func testIsValidAddress_ValidAddress() {
        let validAddress = "0x1234567890123456789012345678901234567890"
        XCTAssertTrue(utils.isValidAddress(validAddress))
    }
    
    func testIsValidAddress_ValidAddressLowercase() {
        let validAddress = "0xabcdef1234567890abcdef1234567890abcdef12"
        XCTAssertTrue(utils.isValidAddress(validAddress))
    }
    
    func testIsValidAddress_ValidAddressUppercase() {
        let validAddress = "0xABCDEF1234567890ABCDEF1234567890ABCDEF12"
        XCTAssertTrue(utils.isValidAddress(validAddress))
    }
    
    func testIsValidAddress_InvalidAddressTooShort() {
        let invalidAddress = "0x123456789012345678901234567890123456789"
        XCTAssertFalse(utils.isValidAddress(invalidAddress))
    }
    
    func testIsValidAddress_InvalidAddressTooLong() {
        let invalidAddress = "0x12345678901234567890123456789012345678901"
        XCTAssertFalse(utils.isValidAddress(invalidAddress))
    }
    
    func testIsValidAddress_InvalidAddressNoPrefix() {
        let invalidAddress = "1234567890123456789012345678901234567890"
        XCTAssertFalse(utils.isValidAddress(invalidAddress))
    }
    
    func testIsValidAddress_InvalidAddressInvalidChars() {
        let invalidAddress = "0x123456789012345678901234567890123456789G"
        XCTAssertFalse(utils.isValidAddress(invalidAddress))
    }
    
    // MARK: - Format Address Tests
    
    func testFormatAddress_LongAddress() {
        let address = "0x1234567890123456789012345678901234567890"
        let formatted = utils.formatAddress(address)
        XCTAssertEqual(formatted, "0x1234...7890")
    }
    
    func testFormatAddress_ShortAddress() {
        let address = "0x123456"
        let formatted = utils.formatAddress(address)
        XCTAssertEqual(formatted, "0x123456") // Should return original if too short
    }
    
    func testFormatAddress_EmptyAddress() {
        let address = ""
        let formatted = utils.formatAddress(address)
        XCTAssertEqual(formatted, "")
    }
    
    // MARK: - Hex to Decimal Tests
    
    func testHexToDecimal_SimpleHex() {
        let hex = "0xff"
        let decimal = utils.hexToDecimal(hex)
        XCTAssertEqual(decimal, Decimal(255))
    }
    
    func testHexToDecimal_HexWithoutPrefix() {
        let hex = "ff"
        let decimal = utils.hexToDecimal(hex)
        XCTAssertEqual(decimal, Decimal(255))
    }
    
    func testHexToDecimal_Zero() {
        let hex = "0x0"
        let decimal = utils.hexToDecimal(hex)
        XCTAssertEqual(decimal, Decimal(0))
    }
    
    func testHexToDecimal_EmptyString() {
        let hex = ""
        let decimal = utils.hexToDecimal(hex)
        XCTAssertEqual(decimal, Decimal(0))
    }
    
    func testHexToDecimal_LargeNumber() {
        let hex = "0x1fffffffffffff"
        let decimal = utils.hexToDecimal(hex)
        XCTAssertEqual(decimal, Decimal(9007199254740991)) // 2^53 - 1
    }
    
    func testHexToDecimal_InvalidHex() {
        let hex = "0xGGG"
        let decimal = utils.hexToDecimal(hex)
        XCTAssertEqual(decimal, Decimal(0)) // Should return 0 for invalid hex
    }
    
    // MARK: - Decimal String to Hex Tests
    
    func testDecimalStringToHex_SimpleNumber() {
        let decimal = "255"
        let hex = utils.decimalStringToHex(decimal)
        XCTAssertEqual(hex, "ff")
    }
    
    func testDecimalStringToHex_Zero() {
        let decimal = "0"
        let hex = utils.decimalStringToHex(decimal)
        XCTAssertEqual(hex, "0")
    }
    
    func testDecimalStringToHex_LargeNumber() {
        let decimal = "9007199254740991"
        let hex = utils.decimalStringToHex(decimal)
        XCTAssertEqual(hex, "1fffffffffffff")
    }
    
    func testDecimalStringToHex_EmptyString() {
        let decimal = ""
        let hex = utils.decimalStringToHex(decimal)
        XCTAssertEqual(hex, "0")
    }
    
    func testDecimalStringToHex_WithNonDigits() {
        let decimal = "123abc456"
        let hex = utils.decimalStringToHex(decimal)
        XCTAssertEqual(hex, "1e240") // Should extract only digits: "123456"
    }
    
    // MARK: - Amount to UInt256 Hex Tests
    
    func testAmountToUInt256Hex_SimpleAmount() throws {
        let amount = "1.5"
        let decimals = 18
        let hex = try utils.amountToUInt256Hex(amount, decimals: decimals)
        // 1.5 * 10^18 = 1500000000000000000 = 0x14d1120d7b160000
        XCTAssertEqual(hex, "14d1120d7b160000")
    }
    
    func testAmountToUInt256Hex_WholeNumber() throws {
        let amount = "10"
        let decimals = 18
        let hex = try utils.amountToUInt256Hex(amount, decimals: decimals)
        // 10 * 10^18 = 10000000000000000000 = 0x8ac7230489e80000
        XCTAssertEqual(hex, "8ac7230489e80000")
    }
    
    func testAmountToUInt256Hex_Zero() throws {
        let amount = "0"
        let decimals = 18
        let hex = try utils.amountToUInt256Hex(amount, decimals: decimals)
        XCTAssertEqual(hex, "0")
    }
    
    func testAmountToUInt256Hex_SmallDecimals() throws {
        let amount = "1.5"
        let decimals = 2
        let hex = try utils.amountToUInt256Hex(amount, decimals: decimals)
        // 1.5 * 10^2 = 150 = 0x96
        XCTAssertEqual(hex, "96")
    }
    
    func testAmountToUInt256Hex_InvalidAmount() {
        let amount = "invalid"
        let decimals = 18
        XCTAssertThrowsError(try utils.amountToUInt256Hex(amount, decimals: decimals)) { error in
            XCTAssertTrue(error is CrossUtilsError)
            if case .invalidAmount(let message) = error as? CrossUtilsError {
                XCTAssertEqual(message, "금액 형식이 올바르지 않습니다")
            }
        }
    }
    
    func testAmountToUInt256Hex_TooManyDecimals() {
        let amount = "1.123456"
        let decimals = 2
        XCTAssertThrowsError(try utils.amountToUInt256Hex(amount, decimals: decimals)) { error in
            XCTAssertTrue(error is CrossUtilsError)
            if case .invalidAmount(let message) = error as? CrossUtilsError {
                XCTAssertEqual(message, "소수 자릿수가 너무 큽니다")
            }
        }
    }
    
    // MARK: - ERC-20 Transfer Data Encoding Tests
    
    func testEncodeERC20TransferData_ValidData() throws {
        let to = "0x1234567890123456789012345678901234567890"
        let amount = "1000"
        let decimals = 18
        
        let encoded = try utils.encodeERC20TransferData(to: to, amount: amount, decimals: decimals)
        
        // Should start with transfer function selector
        XCTAssertTrue(encoded.hasPrefix("0xa9059cbb"))
        
        // Should contain padded address (without 0x prefix)
        let expectedAddress = "0000000000000000000000001234567890123456789012345678901234567890"
        XCTAssertTrue(encoded.contains(expectedAddress))
    }
    
    func testEncodeERC20TransferData_InvalidAddress() {
        let to = "0x123" // Too short
        let amount = "1000"
        let decimals = 18
        
        XCTAssertThrowsError(try utils.encodeERC20TransferData(to: to, amount: amount, decimals: decimals)) { error in
            XCTAssertTrue(error is CrossUtilsError)
            if case .invalidAddress(let message) = error as? CrossUtilsError {
                XCTAssertEqual(message, "수신자 주소 형식이 올바르지 않습니다")
            }
        }
    }
    
    func testEncodeERC20TransferData_InvalidAmount() {
        let to = "0x1234567890123456789012345678901234567890"
        let amount = "invalid"
        let decimals = 18
        
        XCTAssertThrowsError(try utils.encodeERC20TransferData(to: to, amount: amount, decimals: decimals)) { error in
            XCTAssertTrue(error is CrossUtilsError)
        }
    }
    
    // MARK: - Integration Tests
    
    func testHexDecimalRoundTrip() {
        let originalDecimal = "12345678901234567890"
        let hex = utils.decimalStringToHex(originalDecimal)
        let backToDecimal = utils.hexToDecimal("0x" + hex)
        
        XCTAssertEqual(Decimal(string: originalDecimal), backToDecimal)
    }
    
    func testERC20EncodingWithRealValues() throws {
        // Test with USDC transfer (6 decimals)
        let to = "0xdAC17F958D2ee523a2206206994597C13D831ec7" // USDT contract
        let amount = "100.50" // 100.50 USDC
        let decimals = 6
        
        let encoded = try utils.encodeERC20TransferData(to: to, amount: amount, decimals: decimals)
        
        // Verify structure: 0x + 8 char selector + 64 char address + 64 char amount
        XCTAssertEqual(encoded.count, 2 + 8 + 64 + 64) // 0x + selector + padded address + padded amount
        XCTAssertTrue(encoded.hasPrefix("0xa9059cbb"))
    }
}
