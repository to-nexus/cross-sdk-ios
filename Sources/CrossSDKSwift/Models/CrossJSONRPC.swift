//
//  CrossJSONRPC.swift
//  cross-sdk-swift
//
//  Created by Chuck on 9/4/25.
//
import Foundation
import WalletConnectSign

public struct CrossJSONRPCObject: Codable {
    public let jsonrpc: CrossJSONRPC
    public let customData: CustomData?

    public init(jsonrpc: CrossJSONRPC, customData: CustomData? = nil) {
        self.jsonrpc = jsonrpc
        self.customData = customData
    }

    public var rawValues: (method: String, params: [Any]) {
        let (method, jsonrpcParams) = jsonrpc.rawValues

        var paramsArray: [Any] = []

        if method == "personal_sign" {
            let address = jsonrpcParams["address"] as? String ?? ""
            let message = jsonrpcParams["message"] as? String ?? ""
            let messageHex = "0x" + CrossSDKSwift.shared.utils.dataToHex(message.data(using: .utf8) ?? Data())
            paramsArray = [messageHex, address]
            if let customData = customData {
                paramsArray.append(customData.rawValue)
            }
        } else if method == "eth_sign" {
            let address = jsonrpcParams["address"] as? String ?? ""
            let data = jsonrpcParams["data"] as? String ?? ""
            paramsArray = [address, data]
            if let customData = customData {
                paramsArray.append(customData.rawValue)
            }
        } else {
            // Default: keep original object as first param; append customData if exists
            paramsArray = [jsonrpcParams]
            if let customData = customData {
                paramsArray.append(customData.rawValue)
            }
        }

        return (method, paramsArray)
    }
    
    /// 서명 타입 추출
    public var type: CrossSigningType {
        let (method, _) = rawValues
        return CrossSigningType(rawValue: method) ?? .personalSign
    }
}

public struct CustomData: Codable {
    public enum Metadata: Codable, Equatable {
        case object([String: AnyCodable])
        case string(String)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
                return
            }
            if let objectValue = try? container.decode([String: AnyCodable].self) {
                self = .object(objectValue)
                return
            }
            throw DecodingError.typeMismatch(
                Metadata.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected string or object for metadata"
                )
            )
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .string(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            case .object(let value):
                var container = encoder.singleValueContainer()
                try container.encode(value)
            }
        }
    }

    /// TS: metadata: Record<string, unknown> | string
    public let metadata: Metadata

    /// TS: [key: string]: unknown
    public let additional: [String: AnyCodable]

    private struct AnyCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = Int(stringValue)
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    public init(metadata: Metadata, additional: [String: AnyCodable] = [:]) {
        self.metadata = metadata
        self.additional = additional
    }

    /// Convenience initializer for plain/HTML string metadata with optional additional fields
    public init(string: String, additional: [String: Any] = [:]) {
        self.metadata = .string(string)
        self.additional = additional.mapValues { AnyCodable(any: $0) }
    }

    /// Convenience initializer for object metadata with optional additional fields
    public init(object: [String: Any], additional: [String: Any] = [:]) {
        self.metadata = .object(object.mapValues { AnyCodable(any: $0) })
        self.additional = additional.mapValues { AnyCodable(any: $0) }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        var additional: [String: AnyCodable] = [:]
        var decodedMetadata: Metadata?

        for key in container.allKeys {
            if key.stringValue == "metadata" {
                decodedMetadata = try container.decode(Metadata.self, forKey: key)
            } else {
                additional[key.stringValue] = try container.decode(AnyCodable.self, forKey: key)
            }
        }

        guard let metadata = decodedMetadata else {
            throw DecodingError.keyNotFound(
                AnyCodingKey(stringValue: "metadata")!,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "'metadata' key is required"
                )
            )
        }

        self.metadata = metadata
        self.additional = additional
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try container.encode(metadata, forKey: AnyCodingKey(stringValue: "metadata")!)
        for (key, value) in additional {
            try container.encode(value, forKey: AnyCodingKey(stringValue: key)!)
        }
    }

    public var rawValue: [String: Any] {
        var result: [String: Any] = additional.mapValues { $0.value }
        switch metadata {
        case .object(let obj):
            result["metadata"] = obj.mapValues { $0.value }
        case .string(let str):
            result["metadata"] = str
        }
        return result
    }
}

public enum CrossJSONRPC: Codable {
    case personal_sign(
        address: String,
        message: String
    )

    case eth_sign(
        address: String,
        data: String
    )

    case eth_signTypedData_v4(
        address: String,
        types: [String: [EIP712Type]],
        primaryType: String,
        domain: EIP712Domain,
        message: [String: AnyCodable]
    )

    case eth_signTransaction(
        from: String,
        to: String?,
        value: String,
        data: String,
        nonce: Int?,
        gas: String?,
        gasPrice: String?,
        maxFeePerGas: String?,
        maxPriorityFeePerGas: String?,
        gasLimit: String?,
        chainId: String
    )

    case eth_sendTransaction(
        from: String,
        to: String?,
        value: String,
        data: String,
        nonce: Int?,
        gas: String?,
        gasPrice: String?,
        maxFeePerGas: String?,
        maxPriorityFeePerGas: String?,
        gasLimit: String?,
        chainId: String
    )

    public var rawValues: (method: String, params: [String: Any]) {
        let json = try! JSONEncoder().encode(self)
        let dictionary = try! JSONSerialization.jsonObject(with: json) as! [String: [String: Any]]

        let method = dictionary.keys.first!
        let params = dictionary[method]!
        return (method, params)
    }

    public var request: Request? {
        return nil
    }
}
