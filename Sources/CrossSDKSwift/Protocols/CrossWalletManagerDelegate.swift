import Foundation

/// CrossWalletManager의 이벤트를 처리하는 델리게이트
public protocol CrossWalletManagerDelegate: AnyObject {
    /// 지갑 연결 상태가 변경되었을 때 호출
    func walletConnectionStateDidChange(_ state: CrossWalletConnectionState)

    /// 체인이 변경되었을 때 호출
    func walletChainDidChange(_ chain: CrossChain)

    /// 계정이 변경되었을 때 호출
    func walletAccountDidChange(_ address: String)
}
