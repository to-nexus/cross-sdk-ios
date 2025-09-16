import Foundation

public protocol HTTPClientProtocol {
    func request<T: Decodable>(_ type: T.Type, at service: HTTPService) async throws -> T
    func request(service: HTTPService) async throws
    func updateHost(host: String) async
}
