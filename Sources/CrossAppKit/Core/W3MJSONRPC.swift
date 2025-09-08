import Foundation

public struct AddChainNativeCurrency: Codable {
    let name: String
    let symbol: String
    let decimals: Int
    
    public init(name: String, symbol: String, decimals: Int) {
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
    }
}

public struct WatchAssetOptions: Codable {
    let address: String
    let symbol: String?
    let decimals: Int?
    let image: String?
    
    public init(address: String, symbol: String?, decimals: Int?, image: String?) {
        self.address = address
        self.symbol = symbol
        self.decimals = decimals
        self.image = image
    }
}
