import Foundation

/// CrossChainManager의 이벤트를 처리하는 델리게이트
public protocol CrossChainManagerDelegate: AnyObject {
    /// 지갑 승인이 필요한 체인 변경이 완료되었을 때 호출
    func chainDidChange(to chain: CrossChain)

    /// 지갑 승인이 필요한 체인 변경이 실패했을 때 호출
    func chainSwitchDidFail(error: Error)

    /// 즉시 체인 변경이 완료되었을 때 호출
    func chainDidChangeImmediately(to chain: CrossChain)
}

// 기본 구현 제공 (선택적 구현)
extension CrossChainManagerDelegate {
    public func chainDidChange(to chain: CrossChain) {}
    public func chainSwitchDidFail(error: Error) {}
    public func chainDidChangeImmediately(to chain: CrossChain) {}
}
