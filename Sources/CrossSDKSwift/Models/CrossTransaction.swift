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

/// 트랜잭션 Receipt 상태
public enum CrossTransactionReceiptStatus {
    case pending      // 아직 마이닝되지 않음
    case success      // 성공적으로 마이닝됨
    case failed       // 실패함
    case timeout      // 타임아웃
}

/// 트랜잭션 Receipt
public struct CrossTransactionReceipt {
    /// 트랜잭션 해시
    public let transactionHash: String
    
    /// 블록 해시
    public let blockHash: String?
    
    /// 블록 번호
    public let blockNumber: String?
    
    /// 트랜잭션 인덱스
    public let transactionIndex: String?
    
    /// 보낸 주소
    public let from: String
    
    /// 받는 주소
    public let to: String?
    
    /// 사용된 가스
    public let gasUsed: String
    
    /// 누적 가스 사용량
    public let cumulativeGasUsed: String
    
    /// 컨트랙트 주소 (컨트랙트 생성 시)
    public let contractAddress: String?
    
    /// 로그들
    public let logs: [CrossTransactionLog]
    
    /// 상태 (1: 성공, 0: 실패)
    public let status: String
    
    /// Receipt 상태
    public var receiptStatus: CrossTransactionReceiptStatus {
        if status == "0x1" {
            return .success
        } else if status == "0x0" {
            return .failed
        } else {
            return .pending
        }
    }
    
    public init(
        transactionHash: String,
        blockHash: String?,
        blockNumber: String?,
        transactionIndex: String?,
        from: String,
        to: String?,
        gasUsed: String,
        cumulativeGasUsed: String,
        contractAddress: String?,
        logs: [CrossTransactionLog],
        status: String
    ) {
        self.transactionHash = transactionHash
        self.blockHash = blockHash
        self.blockNumber = blockNumber
        self.transactionIndex = transactionIndex
        self.from = from
        self.to = to
        self.gasUsed = gasUsed
        self.cumulativeGasUsed = cumulativeGasUsed
        self.contractAddress = contractAddress
        self.logs = logs
        self.status = status
    }
}

/// 트랜잭션 로그
public struct CrossTransactionLog {
    /// 로그 주소
    public let address: String
    
    /// 토픽들
    public let topics: [String]
    
    /// 데이터
    public let data: String
    
    /// 블록 번호
    public let blockNumber: String?
    
    /// 트랜잭션 해시
    public let transactionHash: String
    
    /// 트랜잭션 인덱스
    public let transactionIndex: String?
    
    /// 블록 해시
    public let blockHash: String?
    
    /// 로그 인덱스
    public let logIndex: String?
    
    public init(
        address: String,
        topics: [String],
        data: String,
        blockNumber: String?,
        transactionHash: String,
        transactionIndex: String?,
        blockHash: String?,
        logIndex: String?
    ) {
        self.address = address
        self.topics = topics
        self.data = data
        self.blockNumber = blockNumber
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
        self.blockHash = blockHash
        self.logIndex = logIndex
    }
}

/// Receipt 폴링 설정
public struct CrossReceiptPollingConfig {
    /// 폴링 간격 (초)
    public let interval: TimeInterval
    
    /// 최대 폴링 시간 (초)
    public let timeout: TimeInterval
    
    /// 최대 재시도 횟수
    public let maxRetries: Int
    
    public init(
        interval: TimeInterval = 2.0,
        timeout: TimeInterval = 300.0, // 5분
        maxRetries: Int = 150 // 5분 / 2초 = 150회
    ) {
        self.interval = interval
        self.timeout = timeout
        self.maxRetries = maxRetries
    }
    
    /// 기본 설정
    public static let `default` = CrossReceiptPollingConfig()
}
