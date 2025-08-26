import Foundation

/// CrossSDKSwift 상세 연결 상태
public enum CrossConnectionState {
    case idle                   // 대기 중
    case connecting            // 연결 시도 중
    case authenticating        // 인증 중
    case connected(CrossWallet) // 연결 완료
    case disconnected          // 연결 해제됨
    case error(Error)          // 에러 발생
}

extension CrossConnectionState: Equatable {
    public static func == (lhs: CrossConnectionState, rhs: CrossConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.connecting, .connecting):
            return true
        case (.authenticating, .authenticating):
            return true
        case (.connected(let lWallet), .connected(let rWallet)):
            return lWallet.address == rWallet.address
        case (.disconnected, .disconnected):
            return true
        case (.error(_), .error(_)):
            return true // 에러 비교는 복잡하므로 타입만 비교
        default:
            return false
        }
    }
}

extension CrossConnectionState {
    /// 사용자 친화적인 상태 설명
    public var description: String {
        switch self {
        case .idle:
            return "Ready to connect"
        case .connecting:
            return "Establishing connection"
        case .authenticating:
            return "Waiting for approval"
        case .connected(let wallet):
            return "Connected to \(wallet.chain.name)"
        case .disconnected:
            return "Connection terminated"
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
    
    /// 현재 상태가 연결된 상태인지 확인
    public var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    /// 현재 상태가 진행 중인 상태인지 확인
    public var isInProgress: Bool {
        switch self {
        case .connecting, .authenticating:
            return true
        default:
            return false
        }
    }
}
