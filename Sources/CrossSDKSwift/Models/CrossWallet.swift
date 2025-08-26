import Foundation

/// 연결된 지갑 정보
public struct CrossWallet {
    /// 지갑 주소
    public let address: String

    /// 현재 연결된 체인
    public let chain: CrossChain

    /// 지갑 이름 (선택사항)
    public let name: String?

    public init(address: String, chain: CrossChain, name: String? = nil) {
        self.address = address
        self.chain = chain
        self.name = name
    }
}

/// 지갑 연결 상태
public enum CrossWalletConnectionState {
    case disconnected
    case connecting
    case connected(CrossWallet)
    case error(Error)
}
