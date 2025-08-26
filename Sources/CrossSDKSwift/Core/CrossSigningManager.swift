import Foundation
import WalletConnectSign
import CrossAppKit
import Combine

/// CrossSDKSwift 서명 매니저
public class CrossSigningManager: ObservableObject {
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var pendingRequests: [String: (Result<CrossSigningResult, Error>) -> Void] = [:]
    
    // MARK: - Initialization
    
    init() {
        
    }
    
    public func configure() {
        setupResponseObserver()
    }
    
    /// Personal Sign 수행
    /// - Parameters:
    ///   - message: 서명할 메시지
    ///   - account: 서명할 계정 주소
    /// - Returns: 서명 결과
    public func personalSign(message: String, account: String) async throws -> CrossSigningResult {
        let originalRequest = CrossSigningRequest(
            type: .personalSign,
            account: account,
            message: message
        )
        
        // AppKit의 W3MJSONRPC를 사용하여 요청
        let appKitRequest = W3MJSONRPC.personal_sign(
            address: account,
            message: message
        )
        
        return try await performAppKitSigningRequest(appKitRequest, originalRequest: originalRequest)
    }
    
    /// ETH Sign 수행 (위험: 원시 바이트 서명)
    /// - Parameters:
    ///   - data: 서명할 원시 데이터 (32바이트)
    ///   - account: 서명할 계정 주소
    /// - Returns: 서명 결과
    public func ethSign(data: Data, account: String) async throws -> CrossSigningResult {
        guard data.count == 32 else {
            throw CrossSigningError.invalidData("ETH sign requires exactly 32 bytes")
        }
        
        let originalRequest = CrossSigningRequest(
            type: .ethSign,
            account: account,
            message: "0x" + data.toHexString(),
            rawData: data
        )
        
        // AppKit의 W3MJSONRPC를 사용하여 요청
        let appKitRequest = W3MJSONRPC.eth_sign(
            address: account,
            data: "0x" + data.toHexString()
        )
        
        return try await performAppKitSigningRequest(appKitRequest, originalRequest: originalRequest)
    }
    
    /// EIP-712 Typed Data V4 서명 수행
    /// - Parameters:
    ///   - typedData: EIP-712 구조화된 데이터
    ///   - account: 서명할 계정 주소
    /// - Returns: 서명 결과
    public func signTypedDataV4(typedData: EIP712TypedData, account: String) async throws -> CrossSigningResult {
        let originalRequest = CrossSigningRequest(
            type: .ethSignTypedDataV4,
            account: account,
            message: "EIP-712 Typed Data: \(typedData.primaryType)"
        )
        
        // EIP-712 데이터를 JSON으로 인코딩
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(typedData)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        // AppKit의 W3MJSONRPC를 사용하여 요청
        let appKitRequest = W3MJSONRPC.eth_signTypedData_v4(
            address: account,
            typedData: jsonString
        )
        
        return try await performAppKitSigningRequest(appKitRequest, originalRequest: originalRequest)
    }
    
    /// 편의 메서드: 간단한 EIP-712 메시지 서명
    /// - Parameters:
    ///   - message: 서명할 메시지
    ///   - account: 서명할 계정 주소
    ///   - domain: 도메인 정보 (선택사항)
    /// - Returns: 서명 결과
    public func signSimpleMessage(message: String, account: String, domain: EIP712Domain? = nil) async throws -> CrossSigningResult {
        let defaultDomain = domain ?? EIP712Domain(
            name: "CrossSDKSwift",
            version: "1.0.0",
            chainId: 1
        )
        
        let types: [String: [EIP712Type]] = [
            "EIP712Domain": [
                EIP712Type(name: "name", type: "string"),
                EIP712Type(name: "version", type: "string"),
                EIP712Type(name: "chainId", type: "uint256")
            ],
            "Message": [
                EIP712Type(name: "content", type: "string")
            ]
        ]
        
        let messageData: [String: Any] = [
            "content": message
        ]
        
        let typedData = EIP712TypedData(
            types: types,
            primaryType: "Message",
            domain: defaultDomain,
            message: messageData
        )
        
        return try await signTypedDataV4(typedData: typedData, account: account)
    }
    
    // MARK: - Private Methods
    
    /// AppKit 기반 서명 요청 수행
    private func performAppKitSigningRequest(_ request: W3MJSONRPC, originalRequest: CrossSigningRequest) async throws -> CrossSigningResult {
        print("🔐 CrossSigningManager: Sending AppKit signing request")
        print("🔐 Method: \(request.rawValues.method)")
        print("🔐 Params: \(request.rawValues.params)")
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // AppKit을 통해 요청 전송 (자동으로 지갑 앱으로 딥링크)
                    try await AppKit.instance.request(request)
                    print("🔐 CrossSigningManager: AppKit request sent successfully")
                    
                    // 🔥 서명 요청 후 지갑 앱으로 이동
                    await MainActor.run {
                        AppKit.instance.launchCurrentWallet()
                        print("✅ CrossSigningManager: Launched current wallet via AppKit")
                    }
                    
                    // 요청 ID를 생성하고 대기 목록에 추가
                    let requestId = UUID().uuidString
                    pendingRequests[requestId] = { result in
                        switch result {
                        case .success(let signingResult):
                            continuation.resume(returning: signingResult)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    
                    // 타임아웃 설정 (30초)
                    Task {
                        try? await Task.sleep(nanoseconds: 30_000_000_000)
                        if let completion = pendingRequests.removeValue(forKey: requestId) {
                            completion(.failure(CrossSigningError.timeout))
                        }
                    }
                    
                } catch {
                    print("🔐 CrossSigningManager: AppKit request failed: \(error)")
                    continuation.resume(throwing: CrossSigningError.requestFailed(error.localizedDescription))
                }
            }
        }
    }
    
    /// 응답 처리 설정 (앱 라이프사이클과 무관하게 지속적으로 구독)
    private func setupResponseObserver() {
        AppKit.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleResponse(response)
            }
            .store(in: &cancellables)
    }
    
    /// 응답 처리
    private func handleResponse(_ response: W3MResponse) {
        print("🔐 CrossSigningManager: Handling response: \(response)")
        
        // 첫 번째 대기 중인 요청에 응답 전달 (FIFO)
        guard let (requestId, completion) = pendingRequests.first else {
            print("🔐 CrossSigningManager: No pending requests")
            return
        }
        
        switch response.result {
        case .response(let result):
            do {
                let signature = try result.get(String.self)
                print("🔐 CrossSigningManager: Signature received: \(signature)")
                
                // 임시로 첫 번째 요청의 정보를 사용 (실제로는 요청 ID 매칭 필요)
                let dummyRequest = CrossSigningRequest(
                    type: .personalSign,
                    account: "",
                    message: "Response received"
                )
                
                let signingResult = CrossSigningResult(
                    signature: signature,
                    request: dummyRequest
                )
                
                completion(.success(signingResult))
                pendingRequests.removeValue(forKey: requestId)
                
            } catch {
                print("🔐 CrossSigningManager: Error parsing signature: \(error)")
                completion(.failure(CrossSigningError.invalidResponse))
                pendingRequests.removeValue(forKey: requestId)
            }
            
        case .error(let error):
            print("🔐 CrossSigningManager: AppKit error: \(error.message)")
            completion(.failure(CrossSigningError.walletConnectError(error.message)))
            pendingRequests.removeValue(forKey: requestId)
        }
    }
    
    /// WalletConnect 서명 요청 수행 (백업용)
    private func performSigningRequest(_ request: Request, originalRequest: CrossSigningRequest) async throws -> CrossSigningResult {
        print("🔐 CrossSigningManager: Sending signing request")
        print("🔐 Request ID: \(request.id)")
        print("🔐 Method: \(request.method)")
        print("🔐 Params: \(request.params)")
        print("🔐 Topic: \(request.topic)")
        
        // 먼저 요청을 전송
        try await Sign.instance.request(params: request)
        print("🔐 CrossSigningManager: Request sent successfully")
        
        // 응답을 기다림
        return try await withCheckedThrowingContinuation { continuation in
            var responseReceived = false
            
            // 응답 구독 - request ID로 필터링하는 것이 더 정확
            let subscription = Sign.instance.sessionResponsePublisher
                .filter { response in
                    print("🔐 CrossSigningManager: Received response for request ID: \(response.id)")
                    return response.id == request.id
                }
                .sink { response in
                    guard !responseReceived else { return }
                    responseReceived = true
                    
                    print("🔐 CrossSigningManager: Processing response...")
                    switch response.result {
                    case .response(let result):
                        do {
                            let signature = try result.get(String.self)
                            print("🔐 CrossSigningManager: Signature received: \(signature)")
                            let signingResult = CrossSigningResult(
                                signature: signature,
                                request: originalRequest
                            )
                            continuation.resume(returning: signingResult)
                        } catch {
                            print("🔐 CrossSigningManager: Error parsing signature: \(error)")
                            continuation.resume(throwing: CrossSigningError.invalidResponse)
                        }
                    case .error(let error):
                        print("🔐 CrossSigningManager: WalletConnect error: \(error.message)")
                        continuation.resume(throwing: CrossSigningError.walletConnectError(error.message))
                    }
                }
            
            // 타임아웃 설정 (30초)
            Task {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30초
                if !responseReceived {
                    responseReceived = true
                    subscription.cancel()
                    continuation.resume(throwing: CrossSigningError.timeout)
                }
            }
        }
    }
}

/// CrossSDKSwift 서명 관련 에러
public enum CrossSigningError: LocalizedError {
    case noActiveSession
    case invalidAccount
    case invalidData(String)
    case invalidResponse
    case walletConnectError(String)
    case requestFailed(String)
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "활성화된 WalletConnect 세션이 없습니다."
        case .invalidAccount:
            return "유효하지 않은 계정입니다."
        case .invalidData(let message):
            return "유효하지 않은 데이터: \(message)"
        case .invalidResponse:
            return "지갑에서 유효하지 않은 응답을 받았습니다."
        case .walletConnectError(let message):
            return "WalletConnect 오류: \(message)"
        case .requestFailed(let message):
            return "요청 실패: \(message)"
        case .timeout:
            return "요청 시간이 초과되었습니다."
        }
    }
}

// Data extension for hex conversion
extension Data {
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
