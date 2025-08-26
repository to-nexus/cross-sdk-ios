//
//  Extensions.swift
//  reown
//
//  Created by Chuck on 8/22/25.
//
import Foundation
import CrossAppKit

public extension Data {
    var bytes: [UInt8] {
        return withUnsafeBytes { Array($0) }
    }
}
