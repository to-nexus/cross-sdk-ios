import Foundation
import CrossAppKit
import Combine

/// 트랜잭션 및 서명을 관리하는 클래스
public class CrossTransactionManager: ObservableObject {

    // MARK: - Properties

    /// 트랜잭션 결과를 받기 위한 델리게이트
    public weak var delegate: CrossTransactionManagerDelegate?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var pendingRequests: [String: (Result<String, Error>) -> Void] = [:]

    // MARK: - Initialization

    init() {
        // AppKit 설정 후에 응답 observer 설정됨
    }

    // MARK: - Public Methods

    /// AppKit 설정 후 초기화
    internal func setupAfterAppKitConfiguration() {
        setupResponseObserver()
    }

    /// 트랜잭션 전송
    /// - Parameter params: 트랜잭션 파라미터
    /// - Returns: 트랜잭션 해시
    public func sendTransaction(_ params: CrossTransactionParams, customData: CustomData? = nil) async throws -> String {
        guard let wallet = getCurrentWallet() else {
            throw CrossSDKError.walletNotConnected
        }

        let valueHex = try convertToWei(params.value)
        let dataHex = params.data ?? "0x"

        let gasHex = try await computeGasHexIfNeeded(
            from: wallet.address,
            to: params.to,
            valueHex: valueHex,
            dataHex: dataHex,
            providedGasLimit: params.gasLimit
        )

        let fee = try await buildFeeConfig(for: params.type, providedGasPrice: params.gasPrice)

        let requestObject = CrossJSONRPCObject(
            jsonrpc: .eth_sendTransaction(
                from: wallet.address,
                to: params.to,
                value: valueHex,
                data: dataHex,
                nonce: nil,
                gas: gasHex,
                gasPrice: fee.gasPriceHex,
                maxFeePerGas: fee.maxFeePerGasHex,
                maxPriorityFeePerGas: fee.maxPriorityFeePerGasHex,
                gasLimit: gasHex,
                chainId: wallet.chain.rawValue
            ),
            customData: customData
        )

        // AppKit 요청을 통해 트랜잭션 해시를 기다렸다가 반환
        let txHash = try await performAppKitTransactionRequest(requestObject)
        return txHash
    }
    
    /// 스마트 컨트랙트의 특정 값을 읽어옴 (view/pure 함수 호출)
    /// - Parameters:
    ///   - contractAddress: 컨트랙트 주소
    ///   - methodName: 호출할 메소드명 (예: "balanceOf")
    ///   - abi: 메소드의 ABI 시그니처 (예: "balanceOf(address)")
    ///   - params: 메소드 파라미터 배열 (예: ["0x123..."])
    /// - Returns: 컨트랙트 함수의 반환값 (hex string)
    public func readContract(
        contractAddress: String,
        methodName: String,
        abi: String,
        params: [String] = []
    ) async throws -> String {
        // 1. ABI 시그니처에서 함수 selector 생성
        let functionSelector = try generateFunctionSelector(abi: abi)
        
        // 2. 파라미터 인코딩
        let encodedParams = try encodeParameters(params: params)
        
        // 3. call data 구성 (selector + encoded params)
        let callData = "0x" + functionSelector + encodedParams
        
        print("🔍 CrossTransactionManager: Reading contract")
        print("   Contract: \(contractAddress)")
        print("   Method: \(methodName)")
        print("   ABI: \(abi)")
        print("   Params: \(params)")
        print("   Call Data: \(callData)")
        
        // 4. eth_call 실행
        return try await performContractCall(
            to: contractAddress,
            data: callData
        )
    }
    
    /// 간단한 컨트랙트 읽기 (파라미터 없는 함수용)
    /// - Parameters:
    ///   - contractAddress: 컨트랙트 주소
    ///   - methodName: 호출할 메소드명
    ///   - abi: 메소드의 ABI 시그니처
    /// - Returns: 컨트랙트 함수의 반환값 (hex string)
    public func readContract(
        contractAddress: String,
        methodName: String,
        abi: String
    ) async throws -> String {
        return try await readContract(
            contractAddress: contractAddress,
            methodName: methodName,
            abi: abi,
            params: []
        )
    }
    
    /// 스마트 컨트랙트 함수 실행 (상태 변경)
    /// - Parameters:
    ///   - contractAddress: 컨트랙트 주소
    ///   - methodName: 호출할 메소드명 (예: "transfer")
    ///   - abi: 메소드의 ABI 시그니처 (예: "transfer(address,uint256)")
    ///   - params: 메소드 파라미터 배열 (예: ["0x123...", "1000000000000000000"])
    ///   - value: 전송할 ETH 양 (기본값: "0")
    ///   - gasLimit: 가스 한도 (옵션, 자동 추정)
    ///   - gasPrice: 가스 가격 (옵션, 자동 조회)
    ///   - type: 트랜잭션 타입 (기본값: .dynamic)
    ///   - customData: 커스텀 데이터 (옵션)
    /// - Returns: 트랜잭션 해시
    public func writeContract(
        contractAddress: String,
        methodName: String,
        abi: String,
        params: [String] = [],
        value: String = "0",
        gasLimit: String? = nil,
        gasPrice: String? = nil,
        type: TransactionType = .dynamic,
        customData: CustomData? = nil
    ) async throws -> String {
        // 1. ABI 시그니처에서 함수 selector 생성
        let functionSelector = try generateFunctionSelector(abi: abi)
        
        // 2. 파라미터 인코딩
        let encodedParams = try encodeParameters(params: params)
        
        // 3. call data 구성 (selector + encoded params)
        let callData = "0x" + functionSelector + encodedParams
        
        print("🔐 CrossTransactionManager: Writing contract")
        print("   Contract: \(contractAddress)")
        print("   Method: \(methodName)")
        print("   ABI: \(abi)")
        print("   Params: \(params)")
        print("   Value: \(value) ETH")
        print("   Call Data: \(callData)")
        
        // 4. CrossTransactionParams 구성
        let transactionParams = CrossTransactionParams(
            to: contractAddress,
            value: value,
            data: callData,
            gasLimit: gasLimit,
            gasPrice: gasPrice,
        )
        
        // 5. sendTransaction을 통해 실행
        return try await sendTransaction(transactionParams, customData: customData)
    }
    
    /// 간단한 컨트랙트 쓰기 (파라미터 없는 함수용)
    /// - Parameters:
    ///   - contractAddress: 컨트랙트 주소
    ///   - methodName: 호출할 메소드명
    ///   - abi: 메소드의 ABI 시그니처
    ///   - value: 전송할 ETH 양 (기본값: "0")
    ///   - gasLimit: 가스 한도 (옵션)
    ///   - gasPrice: 가스 가격 (옵션)
    ///   - type: 트랜잭션 타입 (기본값: .dynamic)
    ///   - customData: 커스텀 데이터 (옵션)
    /// - Returns: 트랜잭션 해시
    public func writeContract(
        contractAddress: String,
        methodName: String,
        abi: String,
        value: String = "0",
        gasLimit: String? = nil,
        gasPrice: String? = nil,
        type: TransactionType = .dynamic,
        customData: CustomData? = nil
    ) async throws -> String {
        return try await writeContract(
            contractAddress: contractAddress,
            methodName: methodName,
            abi: abi,
            params: [],
            value: value,
            gasLimit: gasLimit,
            gasPrice: gasPrice,
            type: type,
            customData: customData
        )
    }

    // MARK: - Private Methods

    private func setupResponseObserver() {
        AppKit.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleResponse(response)
            }
            .store(in: &cancellables)
    }

    private func handleResponse(_ response: W3MResponse) {
        print("🔄 CrossTransactionManager: Handling response: \(response)")

        // 응답 처리 로직
        switch response.result {
        case .response(let result):
            if let stringResult = result.value as? String {
                print("✅ CrossTransactionManager: Success response: \(stringResult)")

                // 🔥 첫 번째 대기 중인 요청에만 응답 전달 (FIFO)
                if let (requestId, completion) = pendingRequests.first {
                    completion(.success(stringResult))
                    pendingRequests.removeValue(forKey: requestId)
                    delegate?.transactionDidSucceed(result: stringResult)
                }
            }
        case .error(let error):
            print("❌ CrossTransactionManager: Error response: \(error)")

            // 🔥 첫 번째 대기 중인 요청에만 에러 전달 (FIFO)
            let nsError = NSError(domain: "CrossSDKSwift", code: error.code, userInfo: [NSLocalizedDescriptionKey: error.message])
            if let (requestId, completion) = pendingRequests.first {
                completion(.failure(nsError))
                pendingRequests.removeValue(forKey: requestId)
                delegate?.transactionDidFail(error: nsError)
            }
        }
    }

    /// 서명을 위해 지갑 앱으로 이동
    @MainActor
    private func navigateToWalletForSigning() async {
        print("🚀 CrossTransactionManager: Navigating to wallet for signing")

        // AppKit의 launchCurrentWallet() 사용 (이미 연결된 지갑 앱 열기)
        AppKit.instance.launchCurrentWallet()

        print("✅ CrossTransactionManager: Launched current wallet via AppKit")
    }

    private func getCurrentWallet() -> CrossWallet? {
        guard let session = CrossSDKSwift.shared.getCurrentSession(),
              let account = session.namespaces.values.first?.accounts.first else {
            return nil
        }

        let address = account.address
        let chainId = account.blockchain.reference

        guard let chain = CrossChain(rawValue: chainId) else {
            return nil
        }

        return CrossWallet(address: address, chain: chain)
    }

    private func convertToWei(_ ethValue: String) throws -> String {
        let trimmed = ethValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^\\d*(?:\\.\\d*)?$"
        guard !trimmed.isEmpty, trimmed.range(of: pattern, options: .regularExpression) != nil else {
            throw NSError(domain: "CrossSDKSwift", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid ETH amount format"])
        }

        guard var decimal = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) else {
            throw NSError(domain: "CrossSDKSwift", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid ETH amount"])
        }

        var scaled = Decimal()
        NSDecimalMultiplyByPowerOf10(&scaled, &decimal, 18, .plain)

        // Ensure integer after scaling
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        guard rounded == scaled else {
            throw NSError(domain: "CrossSDKSwift", code: -1, userInfo: [NSLocalizedDescriptionKey: "Too many fractional digits for 18 decimals"])
        }

        // Convert integer decimal to hex string
        var value = scaled
        let decimalString = NSDecimalString(&value, Locale(identifier: "en_US_POSIX"))
        let hex = decimalStringToHex(decimalString)
        return "0x" + hex
    }

    // MARK: - Gas helpers

    private func computeGasHexIfNeeded(from: String, to: String, valueHex: String, dataHex: String, providedGasLimit: String?) async throws -> String {
        if let provided = providedGasLimit { return provided }
        do {
            return try await estimateGasHex(from: from, to: to, valueHex: valueHex, dataHex: dataHex)
        } catch {
            // 권한 또는 기타 사유로 estimate 실패 시 보수적 기본값으로 대체
            return defaultGasLimitHex(for: dataHex)
        }
    }

    private func defaultGasLimitHex(for dataHex: String) -> String {
        let normalized = dataHex.lowercased()
        if normalized == "0x" || normalized == "0x0" {
            // 네이티브 전송 기본 가스: 21000
            return "0x5208"
        }
        if normalized.hasPrefix("0xa9059cbb") {
            // ERC-20 transfer(address,uint256) 보편적 가스 한도: 100,000
            return "0x186a0"
        }
        // 그 외 컨트랙트 호출은 보수적으로 200,000
        return "0x30d40"
    }

    private struct FeeConfig {
        let gasPriceHex: String?
        let maxFeePerGasHex: String?
        let maxPriorityFeePerGasHex: String?
    }

    private func buildFeeConfig(for type: TransactionType, providedGasPrice: String?) async throws -> FeeConfig {
        switch type {
        case .legacy:
            if providedGasPrice != nil {
                return FeeConfig(gasPriceHex: providedGasPrice, maxFeePerGasHex: nil, maxPriorityFeePerGasHex: nil)
            }
            let gasPrice = try await fetchGasPriceHex()
            return FeeConfig(gasPriceHex: gasPrice, maxFeePerGasHex: nil, maxPriorityFeePerGasHex: nil)
        case .dynamic, .feeDelegated:
            let base = try await fetchGasPriceHex()
            let priority = try await fetchMaxPriorityFeePerGasHex()
            let maxFee = "0x" + hexAdd(strip0x(base), strip0x(priority))
            return FeeConfig(gasPriceHex: nil, maxFeePerGasHex: maxFee, maxPriorityFeePerGasHex: priority)
        }
    }

    private func estimateGasHex(from: String, to: String, valueHex: String, dataHex: String) async throws -> String {
        // 1) 우선 네트워크 RPC로 직접 추정
        if let rpcUrl = AppKit.instance.getSelectedChain()?.rpcUrl {
            do {
                return try await performDirectRPCCall(
                    rpcUrl: rpcUrl,
                    method: "eth_estimateGas",
                    params: [[
                        "from": from,
                        "to": to,
                        "value": valueHex,
                        "data": dataHex
                    ]]
                )
            } catch { /* fallback below */ }
        }
        // 2) 실패 시 세션 RPC로 시도 (권한 필요)
        guard let session = CrossSDKSwift.shared.getCurrentSession(),
              let chain = AppKit.instance.getSelectedChain(),
              let blockchain = Blockchain(namespace: chain.chainNamespace, reference: chain.chainReference) else {
            throw CrossSDKError.walletNotConnected
        }
        let tx: [String: Any] = ["from": from, "to": to, "value": valueHex, "data": dataHex]
        return try await performRPC(method: "eth_estimateGas", params: [tx], topic: session.topic, blockchain: blockchain)
    }

    private func fetchGasPriceHex() async throws -> String {
        if let rpcUrl = AppKit.instance.getSelectedChain()?.rpcUrl {
            if let v = try? await performDirectRPCCall(rpcUrl: rpcUrl, method: "eth_gasPrice", params: []) { return v }
        }
        guard let session = CrossSDKSwift.shared.getCurrentSession(),
              let chain = AppKit.instance.getSelectedChain(),
              let blockchain = Blockchain(namespace: chain.chainNamespace, reference: chain.chainReference) else {
            throw CrossSDKError.walletNotConnected
        }
        return try await performRPC(method: "eth_gasPrice", params: [], topic: session.topic, blockchain: blockchain)
    }

    private func fetchMaxPriorityFeePerGasHex() async throws -> String {
        if let rpcUrl = AppKit.instance.getSelectedChain()?.rpcUrl {
            if let v = try? await performDirectRPCCall(rpcUrl: rpcUrl, method: "eth_maxPriorityFeePerGas", params: []) { return v }
        }
        guard let session = CrossSDKSwift.shared.getCurrentSession(),
              let chain = AppKit.instance.getSelectedChain(),
              let blockchain = Blockchain(namespace: chain.chainNamespace, reference: chain.chainReference) else {
            throw CrossSDKError.walletNotConnected
        }
        return try await performRPC(method: "eth_maxPriorityFeePerGas", params: [], topic: session.topic, blockchain: blockchain)
    }

    private func performRPC(method: String, params: Any, topic: String, blockchain: Blockchain) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let requestId = UUID().uuidString
                    pendingRequests[requestId] = { result in
                        continuation.resume(with: result)
                    }

                    try await AppKit.instance.request(params:
                        .init(
                            topic: topic,
                            method: method,
                            params: AnyCodable(any: params),
                            chainId: blockchain
                        )
                    )
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func performAppKitTransactionRequest(_ requestObject: CrossJSONRPCObject) async throws -> String {
        print("🔐 CrossTransactionManager: Sending AppKit trasaction request")
        let raw = requestObject.rawValues
        print("🔐 Method: \(raw.method)")
        print("🔐 Params: \(raw.params)")

        // 세션 및 체인 정보 확보
        guard let session = CrossSDKSwift.shared.getCurrentSession(),
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

        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<String, Error>) in
            Task { [weak self] in
                do {
                    // AppKit을 통해 요청 전송 (자동으로 지갑 앱으로 딥링크)
                    try await AppKit.instance.request(params: wcRequest)
                    print("🔐 CrossTransactionManager: AppKit request sent successfully")

                    // 🔥 요청 후 지갑 앱으로 이동
                    await MainActor.run {
                        AppKit.instance.launchCurrentWallet()
                        print("✅ CrossTransactionManager: Launched current wallet via AppKit")
                    }

                    // 요청 ID를 생성하고 대기 목록에 추가
                    let requestId = UUID().uuidString
                    self?.pendingRequests[requestId] = { result in
                        switch result {
                        case .success(let txHash):
                            continuation.resume(returning: txHash)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }

                    // 타임아웃 설정 (30초)
                    Task { [weak self] in
                        try? await Task.sleep(nanoseconds: 30_000_000_000)
                        if let completion = self?.pendingRequests.removeValue(forKey: requestId) {
                            completion(.failure(CrossSigningError.timeout))
                        }
                    }

                } catch {
                    print("🔐 CrossTransactionManager: AppKit request failed: \(error)")
                    continuation.resume(throwing: CrossSigningError.requestFailed(error.localizedDescription))
                }
            }
        }
    }

    private func strip0x(_ hex: String) -> String {
        return hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
    }

    private func hexAdd(_ a: String, _ b: String) -> String {
        let aChars = Array(a.lowercased())
        let bChars = Array(b.lowercased())
        let hexMap: [Character: Int] = [
            "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7,
            "8": 8, "9": 9, "a": 10, "b": 11, "c": 12, "d": 13, "e": 14, "f": 15
        ]
        let revHex = Array("0123456789abcdef")

        var i = aChars.count - 1
        var j = bChars.count - 1
        var carry = 0
        var out: [Character] = []

        while i >= 0 || j >= 0 || carry > 0 {
            let av = i >= 0 ? (hexMap[aChars[i]] ?? 0) : 0
            let bv = j >= 0 ? (hexMap[bChars[j]] ?? 0) : 0
            let sum = av + bv + carry
            let digit = sum % 16
            carry = sum / 16
            out.append(revHex[digit])
            i -= 1
            j -= 1
        }

        while out.count > 1 && out.last == "0" { _ = out.popLast() }
        return String(out.reversed())
    }

    // MARK: - Contract Call helpers
    
    /// ABI 시그니처에서 함수 selector 생성
    internal func generateFunctionSelector(abi: String) throws -> String {
        // ABI 시그니처를 keccak256으로 해시하고 첫 4바이트를 사용
        let abiData = Data(abi.utf8)
        let hash = CrossSDKSwift.shared.utils.keccak256(abiData)
        let selector = hash.prefix(4)
        return selector.map { String(format: "%02x", $0) }.joined()
    }
    
    /// 파라미터 인코딩 (간단한 구현 - 주소와 uint256만 지원)
    internal func encodeParameters(params: [String]) throws -> String {
        var encoded = ""
        
        for param in params {
            if param.hasPrefix("0x") && param.count == 42 {
                // 주소 타입 (20바이트를 32바이트로 패딩)
                let address = String(param.dropFirst(2)).lowercased()
                let paddedAddress = String(repeating: "0", count: 24) + address
                encoded += paddedAddress
            } else if param.allSatisfy({ $0.isNumber }) {
                // uint256 타입 (숫자를 32바이트 hex로 변환)
                guard let number = UInt64(param) else {
                    throw NSError(domain: "CrossSDKSwift", code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "Invalid number format: \(param)"])
                }
                let hex = String(number, radix: 16)
                let paddedHex = String(repeating: "0", count: max(0, 64 - hex.count)) + hex
                encoded += paddedHex
            } else if param.hasPrefix("0x") {
                // 이미 hex 형태인 경우 (32바이트로 패딩)
                let hex = String(param.dropFirst(2))
                let paddedHex = String(repeating: "0", count: max(0, 64 - hex.count)) + hex
                encoded += paddedHex
            } else {
                throw NSError(domain: "CrossSDKSwift", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Unsupported parameter type: \(param)"])
            }
        }
        
        return encoded
    }
    
    /// eth_call 실행
    private func performContractCall(to contractAddress: String, data: String) async throws -> String {
        // 1) 우선 네트워크 RPC로 직접 호출 시도
        if let rpcUrl = AppKit.instance.getSelectedChain()?.rpcUrl {
            do {
                return try await performDirectRPCCall(
                    rpcUrl: rpcUrl,
                    method: "eth_call",
                    params: [
                        [
                            "to": contractAddress,
                            "data": data
                        ],
                        "latest"
                    ]
                )
            } catch {
                print("⚠️ Direct RPC call failed, trying session RPC: \(error)")
            }
        }
        
        // 2) 실패 시 세션 RPC로 시도
        guard let session = CrossSDKSwift.shared.getCurrentSession(),
              let chain = AppKit.instance.getSelectedChain(),
              let blockchain = Blockchain(namespace: chain.chainNamespace, reference: chain.chainReference) else {
            throw CrossSDKError.walletNotConnected
        }
        
        let callParams: [String: Any] = [
            "to": contractAddress,
            "data": data
        ]
        
        return try await performRPC(
            method: "eth_call",
            params: [callParams, "latest"],
            topic: session.topic,
            blockchain: blockchain
        )
    }
    
    /// 직접 RPC 호출 (HTTP)
    private func performDirectRPCCall(rpcUrl: String, method: String, params: [Any]) async throws -> String {
        guard let url = URL(string: rpcUrl) else {
            throw NSError(domain: "CrossSDKSwift", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Invalid RPC URL"])
        }
        
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "CrossSDKSwift", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw NSError(domain: "CrossSDKSwift", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "RPC Error: \(message)"])
        }
        
        guard let result = json["result"] as? String else {
            throw NSError(domain: "CrossSDKSwift", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "No result in RPC response"])
        }
        
        return result
    }

    private func decimalStringToHex(_ decimal: String) -> String {
        let digitsOnly = decimal.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted)
        if digitsOnly.isEmpty || digitsOnly == "0" { return "0" }
        var number = digitsOnly
        var hex = ""
        let hexAlphabet = Array("0123456789abcdef")
        while number != "0" {
            let (q, r) = divideDecimalStringBy16(number)
            hex.append(hexAlphabet[r])
            number = q
        }
        return String(hex.reversed())
    }

    private func divideDecimalStringBy16(_ decimal: String) -> (quotient: String, remainder: Int) {
        var carry = 0
        var quotient = ""
        for ch in decimal {
            let d = Int(String(ch)) ?? 0
            let value = carry * 10 + d
            let q = value / 16
            let r = value % 16
            if !(quotient.isEmpty && q == 0) { quotient.append(String(q)) }
            carry = r
        }
        if quotient.isEmpty { quotient = "0" }
        return (quotient, carry)
    }
}

/// CrossTransactionManager의 이벤트를 처리하는 델리게이트
public protocol CrossTransactionManagerDelegate: AnyObject {
    /// 트랜잭션이 성공했을 때 호출
    func transactionDidSucceed(result: String)

    /// 트랜잭션이 실패했을 때 호출
    func transactionDidFail(error: Error)
}
