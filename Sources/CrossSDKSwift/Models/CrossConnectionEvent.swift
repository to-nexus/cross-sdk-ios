import Foundation

/// CrossSDKSwift 연결 관련 이벤트
public enum CrossConnectionEvent {
    case sessionSettling          // 세션 정착 중
    case sessionSettled(CrossWallet)  // 세션 정착 완료
    case sessionDeleted(String)   // 세션 삭제됨 (reason)
    case authenticationSuccess    // 인증 성공
    case authenticationFailed(Error)  // 인증 실패
    case requestExpired          // 요청 만료
}

extension CrossConnectionEvent: Equatable {
    public static func == (lhs: CrossConnectionEvent, rhs: CrossConnectionEvent) -> Bool {
        switch (lhs, rhs) {
        case (.sessionSettling, .sessionSettling):
            return true
        case (.sessionSettled(let lWallet), .sessionSettled(let rWallet)):
            return lWallet.address == rWallet.address
        case (.sessionDeleted(let lReason), .sessionDeleted(let rReason)):
            return lReason == rReason
        case (.authenticationSuccess, .authenticationSuccess):
            return true
        case (.authenticationFailed(_), .authenticationFailed(_)):
            return true // 에러 비교는 복잡하므로 타입만 비교
        case (.requestExpired, .requestExpired):
            return true
        default:
            return false
        }
    }
}
