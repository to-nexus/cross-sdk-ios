import SwiftUI
import CrossSDKSwift
import CrossAppKit
import WalletConnectSign

struct SigningExampleView: View {
    @State private var selectedSigningType: CrossSigningType = .personalSign
    @State private var messageToSign = "Hello, CrossSDKSwift!"
    @State private var customData = ""
    @State private var signatureResult: CrossSigningResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false
    
    // EIP-712 예제 데이터
    @State private var eip712Message = "Welcome to CrossSDKSwift!"
    @State private var eip712DomainName = "CrossSDKSwift"
    @State private var eip712DomainVersion = "1.0.0"
    @State private var eip712ChainId = "1"
    
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
                    SignatureResultView(result: result)
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
                eip712Inputs
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
    
    private var eip712Inputs: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Text("메시지")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("EIP-712 메시지", text: $eip712Message)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("도메인 이름")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("도메인 이름", text: $eip712DomainName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("버전")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("1.0.0", text: $eip712DomainVersion)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("체인 ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("1", text: $eip712ChainId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("서명:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(result.signature)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .truncationMode(.middle)
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
            return !eip712Message.isEmpty && !eip712DomainName.isEmpty
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
        dismissKeyboard()
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
                result = try await CrossSDKSwift.shared.personalSign(message: messageToSign)
                
            case .ethSign:
                let cleanHex = customData.hasPrefix("0x") ? String(customData.dropFirst(2)) : customData
                guard let data = Data(hex: cleanHex) else {
                    throw CrossSigningError.invalidData("유효하지 않은 hex 데이터")
                }
                result = try await CrossSDKSwift.shared.ethSign(data: data)
                
            case .ethSignTypedDataV4:
                let domain = EIP712Domain(
                    name: eip712DomainName,
                    version: eip712DomainVersion,
                    chainId: Int(eip712ChainId) ?? 1
                )
                result = try await CrossSDKSwift.shared.signSimpleMessage(
                    message: eip712Message,
                    domain: domain
                )
            }
            
            signatureResult = result
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - 디버깅 메서드
    private func debugSessionInfo() {
        print("🔍 === 세션 디버깅 정보 ===")
        
        // AppKit 세션 확인
        let sessions = AppKit.instance.getSessions()
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
                    if let blockchain = Blockchain(namespace: "eip155", reference: currentChain.rawValue) {
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

#if canImport(UIKit)
private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
#endif

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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 서명 정보
                    InfoSection(title: "서명 정보") {
                        InfoRow(label: "서명 타입", value: result.request.type.displayName)
                        InfoRow(label: "계정", value: result.request.account)
                        InfoRow(label: "타임스탬프", value: DateFormatter.localizedString(from: result.timestamp, dateStyle: .medium, timeStyle: .medium))
                    }
                    
                    // 메시지 정보
                    InfoSection(title: "메시지") {
                        Text(result.request.message)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
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

// Data extension for hex conversion
extension Data {
    init?(hex: String) {
        let length = hex.count / 2
        var data = Data(capacity: length)
        
        for i in 0..<length {
            let start = hex.index(hex.startIndex, offsetBy: i * 2)
            let end = hex.index(start, offsetBy: 2)
            let hexByte = String(hex[start..<end])
            
            guard let byte = UInt8(hexByte, radix: 16) else {
                return nil
            }
            
            data.append(byte)
        }
        
        self = data
    }
    
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: 32)
        // 간단한 해시 시뮬레이션 (실제로는 CryptoKit 사용 권장)
        for (index, byte) in self.enumerated() {
            hash[index % 32] ^= byte
        }
        return Data(hash)
    }
}

#Preview {
    SigningExampleView()
}
