import Foundation
import WalletConnectSign
import CrossAppKit
import Combine

/// CrossSDKSwift 서명 매니저
public class CrossSigningManager: ObservableObject {

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private struct PendingRequest {
        let original: CrossJSONRPCObject
        let completion: (Result<CrossSigningResult, Error>) -> Void
    }
    private var pendingRequests: [String: PendingRequest] = [:]

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
    public func personalSign(message: String, account: String, customData: CustomData? = nil) async throws -> CrossSigningResult {
        let appKitRequest = CrossJSONRPCObject(
            jsonrpc: .personal_sign(
                address: account,
                message: message
            ),
            customData: customData
        )

        return try await performAppKitSigningRequest(appKitRequest)
    }

    /// ETH Sign 수행 (위험: 원시 바이트 서명)
    /// - Parameters:
    ///   - data: 서명할 원시 데이터 (32바이트)
    ///   - account: 서명할 계정 주소
    /// - Returns: 서명 결과
    public func ethSign(data: Data, account: String, customData: CustomData? = nil) async throws -> CrossSigningResult {
        guard data.count == 32 else {
            throw CrossSigningError.invalidData("ETH sign requires exactly 32 bytes")
        }

        let appKitRequest = CrossJSONRPCObject(
            jsonrpc: .eth_sign(
                address: account,
                data: "0x" + data.toHexString()
            ),
            customData: customData
        )

        return try await performAppKitSigningRequest(appKitRequest)
    }

    /// EIP-712 Typed Data V4 서명 수행
    /// - Parameters:
    ///   - typedData: EIP-712 구조화된 데이터
    ///   - account: 서명할 계정 주소
    /// - Returns: 서명 결과
    public func signTypedDataV4(typedData: EIP712TypedData, account: String, customData: CustomData? = nil) async throws -> CrossSigningResult {
        let appKitRequest = CrossJSONRPCObject(
            jsonrpc: .eth_signTypedData_v4(
                address: account,
                types: typedData.types,
                primaryType: typedData.primaryType,
                domain: typedData.domain,
                message: typedData.message
            ),
            customData: customData
        )

        return try await performAppKitSigningRequest(appKitRequest)
    }

    /// 편의 메서드: 간단한 EIP-712 메시지 서명
    /// - Parameters:
    ///   - message: 서명할 메시지
    ///   - account: 서명할 계정 주소
    ///   - domain: 도메인 정보 (선택사항)
    /// - Returns: 서명 결과
    public func signSimpleMessage(message: String, account: String, domain: EIP712Domain? = nil, customData: CustomData? = nil) async throws -> CrossSigningResult {
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

        return try await signTypedDataV4(typedData: typedData, account: account, customData: customData)
    }

    // MARK: - Private Methods

    /// AppKit 기반 서명 요청 수행
    private func performAppKitSigningRequest(_ requestObject: CrossJSONRPCObject) async throws -> CrossSigningResult {
        print("🔐 CrossSigningManager: Sending AppKit signing request")
        let raw = requestObject.rawValues
        print("🔐 Method: \(raw.method)")
        print("🔐 Params: \(raw.params)")

        // 세션 및 체인 정보 확보
        guard let session = AppKit.instance.getSessions().first,
              let chain = AppKit.instance.getSelectedChain(),
              let blockchain = Blockchain(namespace: chain.chainNamespace, reference: chain.chainReference) else {
            throw CrossSigningError.invalidRequest
        }

        // WalletConnect Request 구성
        let wcRequest = try Request(
            topic: session.topic,
            method: raw.method,
            params: AnyCodable(any: raw.params),
            chainId: blockchain
        )

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // AppKit을 통해 요청 전송 (자동으로 지갑 앱으로 딥링크)
                    try await AppKit.instance.request(params: wcRequest)
                    print("🔐 CrossSigningManager: AppKit request sent successfully")

                    // 🔥 서명 요청 후 지갑 앱으로 이동
                    await MainActor.run {
                        AppKit.instance.launchCurrentWallet()
                        print("✅ CrossSigningManager: Launched current wallet via AppKit")
                    }

                    // 요청 ID를 생성하고 대기 목록에 추가 (원본 요청 저장)
                    let requestId = UUID().uuidString
                    pendingRequests[requestId] = PendingRequest(
                        original: requestObject,
                        completion: { result in
                            switch result {
                            case .success(let signingResult):
                                continuation.resume(returning: signingResult)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                    )

                    // 타임아웃 설정 (30초)
                    Task {
                        try? await Task.sleep(nanoseconds: 30_000_000_000)
                        if let pending = pendingRequests.removeValue(forKey: requestId) {
                            pending.completion(.failure(CrossSigningError.timeout))
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
        guard let (requestId, pending) = pendingRequests.first else {
            print("🔐 CrossSigningManager: No pending requests")
            return
        }

        switch response.result {
        case .response(let result):
            do {
                let signature = try result.get(String.self)
                print("🔐 CrossSigningManager: Signature received: \(signature)")

                // 저장해둔 원본 요청 사용
                let original = pending.original
                let signingResult = CrossSigningResult(signature: signature, request: original)
                pending.completion(.success(signingResult))
                pendingRequests.removeValue(forKey: requestId)

            } catch {
                print("🔐 CrossSigningManager: Error parsing signature: \(error)")
                pending.completion(.failure(CrossSigningError.invalidResponse))
                pendingRequests.removeValue(forKey: requestId)
            }

        case .error(let error):
            print("🔐 CrossSigningManager: AppKit error: \(error.message)")
            pending.completion(.failure(CrossSigningError.walletConnectError(error.message)))
            pendingRequests.removeValue(forKey: requestId)
        }
    }

    /// WalletConnect 서명 요청 수행 (백업용)
    private func performSigningRequest(_ request: Request, originalRequest: CrossJSONRPCObject) async throws -> CrossSigningResult {
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
    case invalidRequest

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
        case .invalidRequest:
            return "잘못된 요청입니다."
        }
    }
}

// Data extension for hex conversion
extension Data {
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
