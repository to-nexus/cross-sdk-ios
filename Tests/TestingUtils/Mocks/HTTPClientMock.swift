import Foundation
import HTTPClient

public final class HTTPClientMock<T: Decodable>: HTTPClientProtocol {
    private let object: T

    public init(object: T) {
        self.object = object
    }

    public func request<U>(_ type: U.Type, at service: HTTPService) async throws -> U where U: Decodable {
        return object as! U
    }

    public func request(service: HTTPService) async throws {

    }
    
    public func updateHost(host: String) async {
        
    }
}
