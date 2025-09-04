import Foundation
public enum TransactionType: Int {
    case legacy = 0
    case dynamic = 1
    case feeDelegated = 7
}
/// 트랜잭션 파라미터
public struct CrossTransactionParams {
    /// 받는 주소
    public let to: String

    /// 전송할 값 (ETH 단위)
    public let value: String

    /// 트랜잭션 데이터 (선택사항)
    public let data: String?

    /// 가스 한도 (선택사항)
    public let gasLimit: String?

    /// 가스 가격 (선택사항)
    public let gasPrice: String?

    /// maxFeePerGas
    public let maxFeePerGas: String?
    
    /// maxFeePerGas
    public let maxPriorityFeePerGas: String?
    
    /// 사용자가 gasLimit과 gasPrice를 설정했다면 legcy로 사용
    public var type: TransactionType {
        if gasLimit != nil && gasPrice != nil {
            return .legacy
        }
        
        return .dynamic
    }
    
    public init(
        to: String,
        value: String,
        data: String? = nil,
        gasLimit: String? = nil,
        gasPrice: String? = nil,
        maxFeePerGas: String? = nil,
        maxPriorityFeePerGas: String? = nil
    ) {
        self.to = to
        self.value = value
        self.data = data
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
    }
}

/// 서명 요청 결과
public enum CrossSignResult {
    case success(String)
    case failure(Error)
}

/// 트랜잭션 전송 결과
public enum CrossTransactionResult {
    case success(String) // 트랜잭션 해시
    case failure(Error)
}
