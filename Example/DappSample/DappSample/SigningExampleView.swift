import SwiftUI
import CrossSDKSwift
import Commons

enum EIP712InputMode: String, CaseIterable {
    case api = "API"
    case json = "JSON"
    
    var title: String {
        switch self {
        case .api:
            return "API에서 가져오기"
        case .json:
            return "JSON 직접 입력"
        }
    }
    
    var description: String {
        switch self {
        case .api:
            return "서버 API에서 EIP-712 데이터를 가져옵니다"
        case .json:
            return "EIP-712 JSON을 직접 입력하여 서명합니다"
        }
    }
}

struct SigningExampleView: View {
    @State private var selectedSigningType: CrossSigningType = .personalSign
    @State private var messageToSign = "Hello, CrossSDKSwift!"
    @State private var customData = ""
    @State private var signatureResult: CrossSigningResult?
    @State private var recoveredAddress: String?
    @State private var verificationOK: Bool = false
    @State private var lastSignedMessage: String = "" // 마지막으로 서명한 원본 메시지 저장
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    // EIP-712 예제 데이터
    @State private var eip712Message = "Welcome to CrossSDKSwift!"
    @State private var eip712DomainName = "CrossSDKSwift"
    @State private var eip712DomainVersion = "1.0.0"
    @State private var eip712ChainId = "1"
    // EIP-712: API 기반 서명 데이터
    @State private var fetchedTypedData: EIP712TypedData?
    @State private var typedDataPreview: String = ""
    @State private var isFetchingTypedData: Bool = false
    
    // EIP-712: JSON 직접 입력
    @State private var eip712InputMode: EIP712InputMode = .api
    @State private var customEIP712JSON: String = ""
    @State private var parsedTypedData: EIP712TypedData?
    @State private var jsonParseError: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    signingTypeSelector
                    inputSection
                    resultSection
                }
                .padding()
            }
            .dismissKeyboardOnInteract()
            .navigationTitle("서명 예제")
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showResult) {
                if let result = signatureResult {
                    SignatureResultView(
                        result: result,
                        recoveredAddress: recoveredAddress,
                        verificationOK: verificationOK,
                        lastSignedMessage: lastSignedMessage
                    )
                }
            }
            .safeAreaInset(edge: .bottom) { bottomSignBar }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "signature")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("CrossSDKSwift 서명 테스트")
                .font(.title2)
                .fontWeight(.bold)

            Text("다양한 서명 타입을 테스트해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 10)
    }

    private var signingTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("서명 타입 선택")
                .font(.headline)

            ForEach(CrossSigningType.allCases, id: \.self) { signingType in
                SigningTypeCard(
                    signingType: signingType,
                    isSelected: selectedSigningType == signingType
                ) {
                    selectedSigningType = signingType
                    resetInputFields()
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("서명 데이터 입력")
                .font(.headline)

            switch selectedSigningType {
            case .personalSign:
                personalSignInputs
            case .ethSign:
                ethSignInputs
            case .ethSignTypedDataV4:
                eip712APISection
            }
        }
    }

    private var personalSignInputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("메시지")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("서명할 메시지를 입력하세요", text: $messageToSign)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))
        }
    }

    private var ethSignInputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("32바이트 해시 데이터 (Hex)")
                .font(.subheadline)
                .fontWeight(.medium)

            Text("⚠️ 주의: ETH Sign은 위험할 수 있습니다")
                .font(.caption)
                .foregroundColor(.orange)

            TextField("0x1234567890abcdef...", text: $customData)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))

            Button("샘플 데이터 생성") {
                generateSampleHashData()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }

    private var eip712APISection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EIP-712 Typed Data v4")
                .font(.headline)
            
            // 입력 모드 선택
            eip712ModeSelector
            
            // 선택된 모드에 따른 입력 섹션
            switch eip712InputMode {
            case .api:
                eip712APIInputSection
            case .json:
                eip712JSONInputSection
            }
        }
    }
    
    private var eip712ModeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("입력 방식")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                ForEach(EIP712InputMode.allCases, id: \.self) { mode in
                    Button(action: {
                        eip712InputMode = mode
                        resetEIP712Data()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.title)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(mode.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(eip712InputMode == mode ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(eip712InputMode == mode ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var eip712APIInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("API에서 데이터 가져오기")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button(action: { Task { await fetchTypedDataFromAPI() } }) {
                    HStack(spacing: 6) {
                        if isFetchingTypedData { ProgressView().scaleEffect(0.7) }
                        Text(isFetchingTypedData ? "가져오는 중..." : "데이터 가져오기")
                    }
                }
                .disabled(isFetchingTypedData)
            }
            
            if !typedDataPreview.isEmpty {
                ScrollView {
                    Text(typedDataPreview)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 200)
            } else if isFetchingTypedData == false && fetchedTypedData == nil {
                Text("아직 데이터가 없습니다. '데이터 가져오기'를 눌러주세요.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var eip712JSONInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EIP-712 JSON 입력")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("예제 JSON") {
                        loadSampleEIP712JSON()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Text("EIP-712 Typed Data JSON을 입력하세요:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // JSON 입력 텍스트 에디터
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $customEIP712JSON)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 200, maxHeight: 300)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(jsonParseError != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: customEIP712JSON) { _ in
                        validateAndParseJSON()
                    }
                
                // JSON 파싱 에러 표시
                if let error = jsonParseError {
                    Text("JSON 파싱 에러: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }
                
                // 파싱 성공 시 미리보기
                if parsedTypedData != nil && jsonParseError == nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("JSON 파싱 성공! 서명할 준비가 되었습니다.")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private var signButton: some View {
        Button(action: performSigning) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                Text(isLoading ? "서명 중..." : "서명 실행")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isLoading ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading || !isInputValid)
    }

    private var bottomSignBar: some View {
        VStack(spacing: 0) {
            signButton
                .padding(.horizontal)
                .padding(.bottom, 10)
        }
        .background(Color(.systemBackground).opacity(0.9))
    }

    private var resultSection: some View {
        Group {
            if let result = signatureResult {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("서명 결과")
                            .font(.headline)

                        Spacer()

                        Button("상세 보기") {
                            showResult = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        // 기본 정보
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "서명 타입", value: result.request.type.displayName)
                            InfoRow(label: "계정", value: result.account)
                            
                            Text("서명:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(result.signature)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                                .truncationMode(.middle)
                        }
                        
                        // 검증 결과
                        VStack(alignment: .leading, spacing: 8) {
                            Text("검증 결과:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let recovered = recoveredAddress {
                                InfoRow(label: "복구된 주소", value: recovered.prefix(20) + "...")
                                InfoRow(label: "검증 상태", value: verificationOK ? "✅ OK" : "❌ Mismatch")
                            } else {
                                InfoRow(label: "검증 상태", value: "❓ Unknown")
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }

    private var isInputValid: Bool {
        switch selectedSigningType {
        case .personalSign:
            return !messageToSign.isEmpty
        case .ethSign:
            return isValidHexData(customData)
        case .ethSignTypedDataV4:
            switch eip712InputMode {
            case .api:
                return fetchedTypedData != nil
            case .json:
                return parsedTypedData != nil && jsonParseError == nil
            }
        }
    }

    private func resetInputFields() {
        messageToSign = "Hello, CrossSDKSwift!"
        customData = ""
        eip712Message = "Welcome to CrossSDKSwift!"
        signatureResult = nil
        errorMessage = nil
    }

    private func generateSampleHashData() {
        // 샘플 32바이트 해시 생성
        let sampleMessage = "CrossSDKSwift Sample Hash"
        if let data = sampleMessage.data(using: .utf8) {
            let hash = data.sha256()
            customData = "0x" + hash.map { String(format: "%02hhx", $0) }.joined()
        }
    }

    private func isValidHexData(_ hex: String) -> Bool {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        return cleanHex.count == 64 && cleanHex.allSatisfy { $0.isHexDigit }
    }

    private func performSigning() {
        Task {
            await signMessage()
        }
    }

    @MainActor
    private func signMessage() async {
        isLoading = true
        errorMessage = nil
        signatureResult = nil

        // 세션 디버깅 정보 출력
        debugSessionInfo()

        do {
            let result: CrossSigningResult

            switch selectedSigningType {
            case .personalSign:
                // 원본 메시지 저장
                lastSignedMessage = messageToSign
                result = try await CrossSDKSwift.shared.personalSign(
                    message: messageToSign,
                    customData: CustomData(
                        string: "This is metadata for signed message",
                        additional: [
                            "timestamp": ISO8601DateFormatter().string(from: Date())
                        ]
                    )
                )

            case .ethSign:
                let cleanHex = customData.hasPrefix("0x") ? String(customData.dropFirst(2)) : customData
                let data = CrossSDKSwift.shared.utils.hexToData( cleanHex)
                result = try await CrossSDKSwift.shared.ethSign(
                    data: data,
                    customData: CustomData(string: "ETH Sign sample metadata")
                )

            case .ethSignTypedDataV4:
                let typedDataToSign: EIP712TypedData
                
                switch eip712InputMode {
                case .api:
                    guard let typed = fetchedTypedData else {
                        throw CrossSigningError.invalidData("API 데이터가 없습니다. 먼저 데이터를 가져오세요")
                    }
                    typedDataToSign = typed
                    
                case .json:
                    guard let typed = parsedTypedData else {
                        throw CrossSigningError.invalidData("JSON 데이터가 유효하지 않습니다. JSON을 확인해주세요")
                    }
                    if jsonParseError != nil {
                        throw CrossSigningError.invalidData("JSON 파싱 에러가 있습니다. JSON을 수정해주세요")
                    }
                    typedDataToSign = typed
                }
                
                result = try await CrossSDKSwift.shared.signTypedDataV4(
                    typedData: typedDataToSign,
                    customData: CustomData(
                        object: [
                            "description": "EIP-712 typed data signature (\(eip712InputMode.rawValue))",
                            "timestamp": ISO8601DateFormatter().string(from: Date()),
                            "inputMode": eip712InputMode.rawValue
                        ]
                    )
                )
            }

            signatureResult = result
            await verifySignature(result)

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - EIP-712 API
    private func fetchTypedDataFromAPI() async {
        guard case .connected(let wallet) = CrossSDKSwift.shared.detailedConnectionState else {
            errorMessage = "지갑 연결이 필요합니다"
            return
        }

        isFetchingTypedData = true
        defer { isFetchingTypedData = false }

        let urlString = "https://dev-cross-ramp-api.crosstoken.io/api/v1/erc20/message/user"
        guard let url = URL(string: urlString) else {
            errorMessage = "잘못된 URL"
            return
        }

        struct Payload: Encodable {
            let account: String
            let amount: String
            let direction: Bool
            let pair_id: Int
            let project_id: String
        }
        let payload = Payload(
            account: wallet.address,
            amount: "1",
            direction: true,
            pair_id: 1,
            project_id: "nexus-ramp-v1"
        )

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                errorMessage = "API 오류: \((response as? HTTPURLResponse)?.statusCode ?? -1)"
                return
            }

            // 응답 파싱 (params[1]를 typedData로 사용)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let dataObj = (json?["data"] as? [String: Any])
            let params = dataObj?["params"] as? [Any]
            guard let typed = params?[1] as? [String: Any] else {
                errorMessage = "유효한 typedData를 찾을 수 없습니다"
                return
            }

            // typed를 EIP712TypedData로 변환
            guard let domain = typed["domain"] as? [String: Any],
                  let primaryType = typed["primaryType"] as? String,
                  let types = typed["types"] as? [String: Any],
                  let message = typed["message"] as? [String: Any] else {
                errorMessage = "typedData 필드 누락"
                return
            }

            // types: [String: [[String: String]]]
            var parsedTypes: [String: [EIP712Type]] = [:]
            for (key, value) in types {
                guard let arr = value as? [[String: Any]] else { continue }
                parsedTypes[key] = arr.compactMap { dict in
                    guard let name = dict["name"] as? String, let type = dict["type"] as? String else { return nil }
                    return EIP712Type(name: name, type: type)
                }
            }

            let chainIdValue: Int? = (domain["chainId"] as? NSNumber)?.intValue ?? (domain["chainId"] as? Int)
            let eipDomain = EIP712Domain(
                name: sanitizeControlChars(domain["name"] as? String),
                version: sanitizeControlChars(domain["version"] as? String),
                chainId: chainIdValue,
                verifyingContract: domain["verifyingContract"] as? String,
                salt: sanitizeControlChars(domain["salt"] as? String)
            )

            let typedData = EIP712TypedData(
                types: parsedTypes,
                primaryType: primaryType,
                domain: eipDomain,
                message: message
            )

            // 미리보기 텍스트 생성
            if let preview = String(data: try JSONSerialization.data(withJSONObject: typed, options: [.prettyPrinted]), encoding: .utf8) {
                typedDataPreview = preview
            }
            fetchedTypedData = typedData

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Signature verification (address recovery)
    @MainActor
    private func verifySignature(_ result: CrossSigningResult) async {
        let (method, params) = result.request.rawValues
        let utils = CrossSDKSwift.shared.utils

        print("🔧 Utils: Using CrossSDKSwift.shared.utils for signature verification")

        // 예상 주소 추출
        let expectedAddress: String
        switch method {
        case "personal_sign":
            expectedAddress = (params[1] as? String) ?? ""
        case "eth_sign":
            expectedAddress = (params[0] as? String) ?? ""
        case "eth_signTypedData_v4":
            if let paramsDict = params.first as? [String: Any],
               let addr = paramsDict["address"] as? String {
                expectedAddress = addr
            } else {
                expectedAddress = CrossSDKSwift.shared.connectedWallet?.address ?? ""
            }
        default:
            expectedAddress = CrossSDKSwift.shared.connectedWallet?.address ?? ""
        }

        // 서명 검증
        let isValid: Bool
        var recoveredAddr: String?

        switch method {
        case "personal_sign":
            // 저장된 원본 메시지 사용 (hex 변환 과정에서 손실 방지)
            if !lastSignedMessage.isEmpty {
                print("🔍 Using saved original message: '\(lastSignedMessage)'")
                isValid = utils.verifyPersonalSign(
                    signature: result.signature,
                    message: lastSignedMessage,
                    expectedAddress: expectedAddress
                )
                recoveredAddr = utils.recoverAddress(
                    signature: result.signature,
                    message: lastSignedMessage,
                    signType: .personalSign
                )
            } else {
                // 폴백: hex에서 복원 시도
                if let hexMessage = params[0] as? String {
                    let cleanHex = hexMessage.replacingOccurrences(of: "0x", with: "")
                    if let originalMessage = utils.hexToString(cleanHex) {
                        print("🔍 Using hex-decoded message: '\(originalMessage)'")
                        isValid = utils.verifyPersonalSign(
                            signature: result.signature,
                            message: originalMessage,
                            expectedAddress: expectedAddress
                        )
                        recoveredAddr = utils.recoverAddress(
                            signature: result.signature,
                            message: originalMessage,
                            signType: .personalSign
                        )
                    } else {
                        isValid = false
                        recoveredAddr = nil
                    }
                } else {
                    isValid = false
                    recoveredAddr = nil
                }
            }

        case "eth_sign":
            if let dataHex = params[1] as? String {
                let data = utils.hexToData(dataHex.replacingOccurrences(of: "0x", with: ""))
                isValid = utils.verifyEthSign(
                    signature: result.signature,
                    data: data,
                    expectedAddress: expectedAddress
                )
                recoveredAddr = utils.recoverAddress(
                    signature: result.signature,
                    message: dataHex,
                    signType: .ethSign
                )
            } else {
                isValid = false
                recoveredAddr = nil
            }

        case "eth_signTypedData_v4":
            // 1순위: 서명 요청에서 직접 typed data 추출
            if let typedDataDict = params.first as? [String: Any],
               let typedDataJSON = try? JSONSerialization.data(withJSONObject: typedDataDict),
               let typed = try? JSONDecoder().decode(EIP712TypedData.self, from: typedDataJSON) {
                
                print("🔍 TypedData V4 verification with extracted data")
                isValid = utils.verifyTypedDataV4(
                    signature: result.signature,
                    typedData: typed,
                    expectedAddress: expectedAddress
                )
                recoveredAddr = utils.recoverAddressFromTypedData(
                    signature: result.signature,
                    typedData: typed
                )
            } else if let typed = parsedTypedData {
                // 2순위: JSON 입력 모드에서 파싱된 데이터 사용
                print("🔍 TypedData V4 verification with parsed JSON data")
                isValid = utils.verifyTypedDataV4(
                    signature: result.signature,
                    typedData: typed,
                    expectedAddress: expectedAddress
                )
                recoveredAddr = utils.recoverAddressFromTypedData(
                    signature: result.signature,
                    typedData: typed
                )
            } else if let typed = fetchedTypedData {
                // 3순위: API에서 가져온 데이터 사용
                print("🔍 TypedData V4 verification with fetched API data")
                isValid = utils.verifyTypedDataV4(
                    signature: result.signature,
                    typedData: typed,
                    expectedAddress: expectedAddress
                )
                recoveredAddr = utils.recoverAddressFromTypedData(
                    signature: result.signature,
                    typedData: typed
                )
            } else {
                print("❌ No typed data available for verification")
                isValid = false
                recoveredAddr = nil
            }

        default:
            isValid = false
            recoveredAddr = nil
        }

        self.recoveredAddress = recoveredAddr
        self.verificationOK = isValid
    }

    // MARK: - Sanitize helpers
    private func sanitizeControlChars(_ str: String?) -> String? {
        guard let s = str else { return nil }
        // Remove ASCII control characters including NUL (\u0000-\u001F and \u007F)
        let cleaned = s.unicodeScalars.filter { scalar in
            let v = scalar.value
            return !(v <= 0x1F || v == 0x7F)
        }
        return String(String.UnicodeScalarView(cleaned))
    }

    // MARK: - EIP-712 JSON Helpers
    
    private func resetEIP712Data() {
        switch eip712InputMode {
        case .api:
            fetchedTypedData = nil
            typedDataPreview = ""
        case .json:
            customEIP712JSON = ""
            parsedTypedData = nil
            jsonParseError = nil
        }
    }
    
    private func loadSampleEIP712JSON() {
        let sampleJSON = """
        {
          "types": {
            "EIP712Domain": [
              {
                "name": "name",
                "type": "string"
              },
              {
                "name": "version",
                "type": "string"
              },
              {
                "name": "chainId",
                "type": "uint256"
              },
              {
                "name": "verifyingContract",
                "type": "address"
              }
            ],
            "Person": [
              {
                "name": "name",
                "type": "string"
              },
              {
                "name": "wallet",
                "type": "address"
              }
            ],
            "Mail": [
              {
                "name": "from",
                "type": "Person"
              },
              {
                "name": "to",
                "type": "Person"
              },
              {
                "name": "contents",
                "type": "string"
              }
            ]
          },
          "primaryType": "Mail",
          "domain": {
            "name": "CrossSDKSwift Mail",
            "version": "1",
            "chainId": 1,
            "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
          },
          "message": {
            "from": {
              "name": "Alice",
              "wallet": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            },
            "to": {
              "name": "Bob",
              "wallet": "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            },
            "contents": "Hello Bob! This is a test message from CrossSDKSwift."
          }
        }
        """
        
        customEIP712JSON = sampleJSON
        validateAndParseJSON()
    }
    
    private func loadNullTestEIP712JSON() {
        let nullTestJSON = """
        {
          "types": {
            "EIP712Domain": [
              {
                "name": "name",
                "type": "string"
              },
              {
                "name": "version",
                "type": "string"
              },
              {
                "name": "chainId",
                "type": "uint256"
              },
              {
                "name": "verifyingContract",
                "type": "address"
              }
            ],
            "ERC721Mint": [
              {
                "name": "token",
                "type": "address"
              },
              {
                "name": "tokenID",
                "type": "uint256"
              },
              {
                "name": "data",
                "type": "bytes"
              },
              {
                "name": "nonce",
                "type": "uint256"
              },
              {
                "name": "deadline",
                "type": "uint256"
              }
            ]
          },
          "primaryType": "ERC721Mint",
          "domain": {
            "name": "0dba9dc6cc512f72e1a684f531f65150",
            "version": "1",
            "chainId": 612044,
            "verifyingContract": "0xdae286eb6ffc3a36a5d6d5aca56fb0427c1a7c35"
          },
          "message": {
            "data": null,
            "deadline": "1758512723",
            "nonce": "14",
            "token": "0x756ff114493e25d56418b19835be8736c26fb3f1",
            "tokenID": "0"
          }
        }
        """
        
        customEIP712JSON = nullTestJSON
        validateAndParseJSON()
    }
    
    private func validateAndParseJSON() {
        guard !customEIP712JSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            parsedTypedData = nil
            jsonParseError = nil
            return
        }
        
        do {
            // JSON 데이터로 변환
            let jsonData = customEIP712JSON.data(using: .utf8) ?? Data()
            
            // 먼저 일반 JSON 파싱으로 구조 확인
            if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) {
                print("🔍 JSON 구조 확인:")
                print("📝 JSON Object: \(jsonObject)")
            }
            
            // EIP712TypedData로 디코딩 시도
            let decoder = JSONDecoder()
            let typedData = try decoder.decode(EIP712TypedData.self, from: jsonData)
            
            // 성공적으로 파싱됨
            parsedTypedData = typedData
            jsonParseError = nil
            
            print("✅ EIP-712 JSON 파싱 성공")
            print("📝 Primary Type: \(typedData.primaryType)")
            print("📝 Domain: \(typedData.domain)")
            print("📝 Message keys: \(typedData.message.keys)")
            
            // null 값 확인
            for (key, value) in typedData.message {
                if value.value is NSNull {
                    print("🔍 Found null value for key: \(key)")
                } else {
                    print("🔍 \(key): \(value.value) (type: \(type(of: value.value)))")
                }
            }
            
        } catch {
            // 파싱 실패
            parsedTypedData = nil
            jsonParseError = error.localizedDescription
            
            print("❌ EIP-712 JSON 파싱 실패: \(error)")
            
            // 더 자세한 에러 정보
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                    print("❌ Coding path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("❌ Key not found: \(key)")
                    print("❌ Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type)")
                    print("❌ Context: \(context.debugDescription)")
                    print("❌ Coding path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type)")
                    print("❌ Context: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
            }
        }
    }

    // MARK: - UI Sections


    // MARK: - 디버깅 메서드
    private func debugSessionInfo() {
        print("🔍 === 세션 디버깅 정보 ===")

        // AppKit 세션 확인
        let sessions = CrossSDKSwift.shared.getSessions()
        print("🔍 AppKit 세션 개수: \(sessions.count)")

        if let session = sessions.first {
            print("🔍 세션 토픽: \(session.topic)")
            print("🔍 세션 네임스페이스: \(session.namespaces.keys)")

            // eip155 네임스페이스 확인
            if let eip155Namespace = session.namespaces["eip155"] {
                print("🔍 eip155 계정들: \(eip155Namespace.accounts)")
                print("🔍 eip155 허용된 메서드들: \(Array(eip155Namespace.methods))")
                print("🔍 eip155 이벤트들: \(Array(eip155Namespace.events))")

                // eth_sign 메서드 확인
                let hasEthSign = eip155Namespace.methods.contains("eth_sign")
                print("🔍 eth_sign 메서드 포함 여부: \(hasEthSign ? "✅" : "❌")")

                // 현재 체인 확인
                if let currentChain = CrossSDKSwift.shared.currentChain {
                    print("🔍 현재 체인: \(currentChain.name) (\(currentChain.rawValue))")

                    // 현재 체인에 대한 권한 확인
                    if let blockchain = currentChain.blockchain {
                        // 수동으로 권한 확인
                        let hasAccount = eip155Namespace.accounts.contains { $0.blockchain == blockchain }
                        let hasEthSignMethod = eip155Namespace.methods.contains("eth_sign")
                        let hasPermission = hasAccount && hasEthSignMethod

                        print("🔍 현재 체인 계정 존재: \(hasAccount ? "✅" : "❌")")
                        print("🔍 eth_sign 메서드 존재: \(hasEthSignMethod ? "✅" : "❌")")
                        print("🔍 현재 체인에서 eth_sign 권한: \(hasPermission ? "✅" : "❌")")

                        // 계정 상세 정보
                        let matchingAccounts = eip155Namespace.accounts.filter { $0.blockchain == blockchain }
                        print("🔍 매칭되는 계정들: \(matchingAccounts)")
                    }
                }
            } else {
                print("🔍 ❌ eip155 네임스페이스를 찾을 수 없음")
            }
        } else {
            print("🔍 ❌ 활성 세션이 없음")
        }

        print("🔍 === 디버깅 정보 끝 ===")
    }
}

// EIP712LocalHasher 제거됨 - CrossSDKSwift.shared.utils.hashTypedData 사용

struct SigningTypeCard: View {
    let signingType: CrossSigningType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(signingType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(signingType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SignatureResultView: View {
    let result: CrossSigningResult
    let recoveredAddress: String?
    let verificationOK: Bool
    let lastSignedMessage: String // 원본 메시지 추가
    @State private var localRecovered: String?
    @State private var localVerificationOK: Bool = false
    @Environment(\.dismiss) private var dismiss

    private var signingInfoContent: some View {
        let (method, params) = result.request.rawValues
        let displayName: String
        let account: String

        switch method {
        case "personal_sign":
            displayName = "Personal Sign"
            account = (params[1] as? String) ?? ""
        case "eth_sign":
            displayName = "ETH Sign"
            account = (params[0] as? String) ?? ""
        case "eth_signTypedData_v4":
            displayName = "EIP-712 Typed Data V4"
            if let paramsDict = params.first as? [String: Any],
               let addr = paramsDict["address"] as? String {
                account = addr
            } else {
                account = CrossSDKSwift.shared.connectedWallet?.address ?? ""
            }
        default:
            displayName = method
            account = ""
        }

        return Group {
            InfoRow(label: "서명 타입", value: displayName)
            InfoRow(label: "계정", value: account)
            InfoRow(label: "타임스탬프", value: DateFormatter.localizedString(from: result.timestamp, dateStyle: .medium, timeStyle: .medium))
        }
    }

    private var messageInfoContent: some View {
        let (method, params) = result.request.rawValues
        let messageText: String

        switch method {
        case "personal_sign":
            if let hexMessage = params[0] as? String {
                let cleanHex = hexMessage.replacingOccurrences(of: "0x", with: "")
                let data = CrossSDKSwift.shared.utils.hexToData(cleanHex)
                if let originalMessage = String(data: data, encoding: .utf8) {
                    messageText = originalMessage
                } else {
                    messageText = hexMessage
                }
            } else {
                messageText = "Unknown message"
            }
        case "eth_sign":
            messageText = (params[1] as? String) ?? "Unknown data"
        case "eth_signTypedData_v4":
            if let paramsDict = params.first as? [String: Any] {
                messageText = "EIP-712 Typed Data: \(paramsDict["primaryType"] as? String ?? "Unknown")"
            } else {
                messageText = "EIP-712 Typed Data"
            }
        default:
            messageText = "Unknown message type"
        }

        return Text(messageText)
            .font(.system(.body, design: .monospaced))
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 서명 정보
                    InfoSection(title: "서명 정보") {
                        signingInfoContent
                    }

                    // 메시지 정보
                    InfoSection(title: "메시지") {
                        messageInfoContent
                    }

                    // 서명 결과
                    InfoSection(title: "서명 결과") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("서명:")
                                    .fontWeight(.medium)

                                Spacer()

                                Button("복사") {
                                    UIPasteboard.general.string = result.signature
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }

                            Text(result.signature)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .textSelection(.enabled)

                            Divider().padding(.vertical, 6)
                            InfoRow(label: "복구 주소", value: localRecovered ?? "-")
                            InfoRow(label: "검증 결과", value: localRecovered == nil ? "Unknown" : (localVerificationOK ? "OK" : "Mismatch"))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("서명 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 초기 전달값 반영 후 항상 자체 검증도 수행 (정확도 보장)
                self.localRecovered = recoveredAddress
                self.localVerificationOK = verificationOK
                Task { await self.computeRecovery() }
            }
        }
    }

    @MainActor
    private func computeRecovery() async {
        let (method, params) = result.request.rawValues
        let utils = CrossSDKSwift.shared.utils

        // 예상 주소 추출
        let expectedAddress: String
        switch method {
        case "personal_sign":
            expectedAddress = (params[1] as? String) ?? ""
        case "eth_sign":
            expectedAddress = (params[0] as? String) ?? ""
        default:
            expectedAddress = CrossSDKSwift.shared.connectedWallet?.address ?? ""
        }

        // 주소 복구
        let recoveredAddr: String?
        switch method {
        case "personal_sign":
            // 저장된 원본 메시지 사용
            if !lastSignedMessage.isEmpty {
                recoveredAddr = utils.recoverAddress(
                    signature: result.signature,
                    message: lastSignedMessage,
                    signType: .personalSign
                )
            } else {
                // 폴백: hex에서 복원 시도
                if let hexMessage = params[0] as? String,
                   let originalMessage = utils.hexToString(hexMessage.replacingOccurrences(of: "0x", with: "")) {
                    recoveredAddr = utils.recoverAddress(
                        signature: result.signature,
                        message: originalMessage,
                        signType: .personalSign
                    )
                } else {
                    recoveredAddr = nil
                }
            }

        case "eth_sign":
            if let dataHex = params[1] as? String {
                recoveredAddr = utils.recoverAddress(
                    signature: result.signature,
                    message: dataHex,
                    signType: .ethSign
                )
            } else {
                recoveredAddr = nil
            }

        case "eth_signTypedData_v4":
            // TypedData는 별도 처리 필요 - 현재는 스킵
            recoveredAddr = nil

        default:
            recoveredAddr = nil
        }

        self.localRecovered = recoveredAddr
        if let recovered = recoveredAddr {
            self.localVerificationOK = recovered.lowercased() == expectedAddress.lowercased()
        } else {
            self.localVerificationOK = false
        }
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.medium)

            Spacer()

            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SigningExampleView()
}
