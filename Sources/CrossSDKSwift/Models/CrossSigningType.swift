import Foundation
import Commons

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

/// 서명 결과
public struct CrossSigningResult {
    public let signature: String
    public let request: CrossJSONRPCObject
    public let account: String
    public let timestamp: Date

    public init(signature: String, request: CrossJSONRPCObject, account: String) {
        self.signature = signature
        self.request = request
        self.account = account
        self.timestamp = Date()
    }
}

/// EIP-712 Typed Data 구조
public struct EIP712TypedData: Codable {
    public let types: [String: [EIP712Type]]
    public let primaryType: String
    public let domain: EIP712Domain
    public let message: [String: AnyCodable]

    public init(
        types: [String: [EIP712Type]],
        primaryType: String,
        domain: EIP712Domain,
        message: [String: AnyCodable]
    ) {
        self.types = types
        self.primaryType = primaryType
        self.domain = domain
        self.message = message
    }

    /// Convenience initializer for callers that have a [String: Any]
    public init(
        types: [String: [EIP712Type]],
        primaryType: String,
        domain: EIP712Domain,
        message: [String: Any]
    ) {
        self.init(
            types: types,
            primaryType: primaryType,
            domain: domain,
            message: message.mapValues { AnyCodable(any: $0) }
        )
    }
}

public extension EIP712TypedData {
    /// Build CrossJSONRPC.eth_signTypedData_v4 payload from typed data and address
    func asJSONRPC(address: String) -> CrossJSONRPC {
        return .eth_signTypedData_v4(
            address: address,
            types: types,
            primaryType: primaryType,
            domain: domain,
            message: message
        )
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

// Removed private AnyCodable in favor of shared AnyCodable from Commons
