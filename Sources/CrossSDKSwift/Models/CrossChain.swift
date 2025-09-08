import Foundation
import WalletConnectUtils
import CrossAppKit

/// CrossSDKSwift에서 사용하는 체인 정의 (ChainPresets.crossWalletChains 기반)
public enum CrossChain: String, CaseIterable {
    case crossMainnet = "612055"
    case crossTestnet = "612044"
    case bscMainnet = "56"
    case bscTestnet = "97"
    case kaiaMainnet = "8217"
    case kaiaTestnet = "1001"
    case ethereum = "1"
    case ethereumSepolia = "11155111"

    /// ChainPresets에서 체인 정보 조회 (단일 소스)
    private var chainInfo: Chain {
        guard let chain = ChainPresets.crossWalletChains.first(where: { $0.chainReference == self.rawValue }) else {
            fatalError("Chain with reference \(self.rawValue) not found in ChainPresets.crossWalletChains")
        }
        return chain
    }

    /// 체인 이름
    public var name: String {
        return chainInfo.chainName
    }

    /// 체인 심볼
    public var symbol: String {
        return chainInfo.token.symbol
    }

    /// RPC URL
    public var rpcUrl: String {
        return chainInfo.rpcUrl
    }

    /// Block Explorer URL
    public var explorerUrl: String {
        return chainInfo.blockExplorerUrl
    }

    /// 체인 네임스페이스
    public var namespace: String {
        return chainInfo.chainNamespace
    }

    /// 토큰 정보
    public var tokenName: String {
        return chainInfo.token.name
    }

    /// 토큰 소수점 자릿수
    public var decimals: Int {
        return chainInfo.token.decimal
    }

    /// 이미지 ID
    public var imageId: String {
        return chainInfo.imageId
    }

    /// WalletConnect Blockchain 객체 생성
    /// - Returns: 해당 체인에 대한 Blockchain 객체 (eip155 namespace)
    public var blockchain: Blockchain? {
        return Blockchain(namespace: "eip155", reference: self.rawValue)
    }
}
