//
//  Extensions.swift
//  reown
//
//  Created by Chuck on 8/22/25.
//
import Foundation
import CrossAppKit
import WalletConnectUtils

public extension Data {
    var bytes: [UInt8] {
        return withUnsafeBytes { Array($0) }
    }
    
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    init(hexString: String) {
        self.init(hex: hexString)
    }
}

 
