import Foundation

/// CrossSDKSwift에서 지원하는 서명 타입들
public enum CrossSigningType: String, CaseIterable {
    case personalSign = "personal_sign"
    case ethSign = "eth_sign"
    case ethSignTypedDataV4 = "eth_signTypedData_v4"
    
    /// 서명 타입의 표시용 이름
    public var displayName: String {
        switch self {
        case .personalSign:
            return "Personal Sign"
        case .ethSign:
            return "ETH Sign"
        case .ethSignTypedDataV4:
            return "EIP-712 Typed Data V4"
        }
    }
    
    /// 서명 타입의 설명
    public var description: String {
        switch self {
        case .personalSign:
            return "사용자가 읽을 수 있는 메시지에 서명합니다."
        case .ethSign:
            return "원시 바이트 데이터에 서명합니다. (위험할 수 있음)"
        case .ethSignTypedDataV4:
            return "구조화된 데이터에 서명합니다. (EIP-712 표준)"
        }
    }
    
    /// 서명 방법 (WalletConnect RPC method)
    public var rpcMethod: String {
        return self.rawValue
    }
}

/// 서명 요청 데이터
public struct CrossSigningRequest {
    public let type: CrossSigningType
    public let account: String
    public let message: String
    public let rawData: Data?
    
    public init(type: CrossSigningType, account: String, message: String, rawData: Data? = nil) {
        self.type = type
        self.account = account
        self.message = message
        self.rawData = rawData
    }
}

/// 서명 결과
public struct CrossSigningResult {
    public let signature: String
    public let request: CrossSigningRequest
    public let timestamp: Date
    
    public init(signature: String, request: CrossSigningRequest) {
        self.signature = signature
        self.request = request
        self.timestamp = Date()
    }
}

/// EIP-712 Typed Data 구조
public struct EIP712TypedData: Codable {
    public let types: [String: [EIP712Type]]
    public let primaryType: String
    public let domain: EIP712Domain
    public let message: [String: Any]
    
    public init(types: [String: [EIP712Type]], primaryType: String, domain: EIP712Domain, message: [String: Any]) {
        self.types = types
        self.primaryType = primaryType
        self.domain = domain
        self.message = message
    }
    
    enum CodingKeys: String, CodingKey {
        case types, primaryType, domain, message
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(types, forKey: .types)
        try container.encode(primaryType, forKey: .primaryType)
        try container.encode(domain, forKey: .domain)
        
        // message는 [String: Any]이므로 특별한 처리가 필요
        let messageData = try JSONSerialization.data(withJSONObject: message)
        let messageJson = try JSONSerialization.jsonObject(with: messageData) as! [String: Any]
        try container.encode(AnyCodable(messageJson), forKey: .message)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        types = try container.decode([String: [EIP712Type]].self, forKey: .types)
        primaryType = try container.decode(String.self, forKey: .primaryType)
        domain = try container.decode(EIP712Domain.self, forKey: .domain)
        
        let anyCodableMessage = try container.decode(AnyCodable.self, forKey: .message)
        guard let messageDict = anyCodableMessage.value as? [String: Any] else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected dictionary"))
        }
        message = messageDict
    }
}

/// EIP-712 타입 정의
public struct EIP712Type: Codable {
    public let name: String
    public let type: String
    
    public init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}

/// EIP-712 도메인 정보
public struct EIP712Domain: Codable {
    public let name: String?
    public let version: String?
    public let chainId: Int?
    public let verifyingContract: String?
    public let salt: String?
    
    public init(name: String? = nil, version: String? = nil, chainId: Int? = nil, verifyingContract: String? = nil, salt: String? = nil) {
        self.name = name
        self.version = version
        self.chainId = chainId
        self.verifyingContract = verifyingContract
        self.salt = salt
    }
}

// AnyCodable helper for encoding/decoding [String: Any]
private struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let arrayValue = value as? [Any] {
            try container.encode(arrayValue.map { AnyCodable($0) })
        } else if let dictValue = value as? [String: Any] {
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Invalid value"))
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid value"))
        }
    }
}
