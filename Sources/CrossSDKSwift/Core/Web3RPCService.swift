import Foundation

/// Lightweight JSON-RPC client for EVM nodes (used for gas estimation without wallet permissions)
public enum Web3RPCService {
    struct RPCError: LocalizedError, Decodable { let code: Int; let message: String; var errorDescription: String? { message } }
    private struct RPCRequest<P: Encodable>: Encodable { let jsonrpc = "2.0"; let method: String; let params: P; let id: Int }
    private struct RPCResponse<T: Decodable>: Decodable { let jsonrpc: String; let id: Int; let result: T?; let error: RPCError? }

    static func estimateGasHex(rpcUrl: String, from: String, to: String, valueHex: String, dataHex: String) async throws -> String {
        let tx: [String: String] = [
            "from": from,
            "to": to,
            "value": valueHex,
            "data": dataHex
        ]
        let req = RPCRequest(method: "eth_estimateGas", params: [tx], id: 1)
        let res: RPCResponse<String> = try await post(url: rpcUrl, body: req)
        if let err = res.error { throw err }
        guard let result = res.result else { throw RPCError(code: -1, message: "No result from eth_estimateGas") }
        return result
    }

    static func gasPriceHex(rpcUrl: String) async throws -> String {
        let req = RPCRequest<[String]>(method: "eth_gasPrice", params: [], id: 1)
        let res: RPCResponse<String> = try await post(url: rpcUrl, body: req)
        if let err = res.error { throw err }
        guard let result = res.result else { throw RPCError(code: -1, message: "No result from eth_gasPrice") }
        return result
    }

    static func maxPriorityFeePerGasHex(rpcUrl: String) async throws -> String {
        let req = RPCRequest<[String]>(method: "eth_maxPriorityFeePerGas", params: [], id: 1)
        let res: RPCResponse<String> = try await post(url: rpcUrl, body: req)
        if let err = res.error { throw err }
        guard let result = res.result else { throw RPCError(code: -1, message: "No result from eth_maxPriorityFeePerGas") }
        return result
    }

    // MARK: - HTTP
    private static func post<T: Decodable, B: Encodable>(url: String, body: B) async throws -> T {
        guard let endpoint = URL(string: url) else { throw RPCError(code: -1, message: "Invalid RPC URL") }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw RPCError(code: -1, message: "RPC HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? -1) - \(text)")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

