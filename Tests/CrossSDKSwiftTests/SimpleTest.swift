import XCTest

final class SimpleTest: XCTestCase {
    
    func testBasicAssertion() {
        // Given
        let expected = "Hello, World!"
        let actual = "Hello, World!"
        
        // Then
        XCTAssertEqual(actual, expected, "Basic string comparison should work")
    }
    
    func testHexConversion() {
        // Given
        let data = Data([0x48, 0x65, 0x6c, 0x6c, 0x6f])
        
        // When
        let hexString = data.map { String(format: "%02x", $0) }.joined()
        
        // Then
        XCTAssertEqual(hexString, "48656c6c6f", "Hex conversion should work correctly")
    }
}
