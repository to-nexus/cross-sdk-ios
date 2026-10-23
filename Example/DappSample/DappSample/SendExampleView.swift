import SwiftUI
import CrossSDKSwift

struct SendExampleView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    @State private var selectedTab: SendTab = .native
    @State private var receiverAddress: String = ""
    @State private var amountText: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var txHash: String?
    @State private var showResult: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    tabSelector
                    inputSection
                    resultSection
                }
                .padding()
            }
            .navigationTitle("전송 예제")
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") { errorMessage = nil }
            } message: {
                if let error = errorMessage { Text(error) }
            }
            .sheet(isPresented: $showResult) {
                if let txHash = txHash {
                    TxResultView(txHash: txHash)
                }
            }
            .safeAreaInset(edge: .bottom) { bottomSendBar }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 44))
                .foregroundColor(.blue)
            Text("토큰 전송 테스트")
                .font(.title3)
                .fontWeight(.semibold)
            Text("네이티브/ ERC-20 전송을 시험해 보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
            currentNetworkBadge
        }
        .padding(.bottom, 8)
    }

    private var currentNetworkBadge: some View {
        let name = sdk.currentChain?.name ?? "체인 미선택"
        let symbol = sdk.currentChain?.symbol ?? "ETH"
        return HStack(spacing: 6) {
            Image(systemName: "globe")
                .font(.caption)
                .foregroundColor(.blue)
            Text("현재 네트워크: \(name) (\(symbol))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var tabSelector: some View {
        HStack(spacing: 8) {
            TabPill(title: "네이티브 전송", isSelected: selectedTab == .native) {
                selectedTab = .native
            }
            TabPill(title: "ERC-20 전송", isSelected: selectedTab == .erc20) {
                selectedTab = .erc20
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("전송 정보")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("받는 주소")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("0x...", text: $receiverAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("금액")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Button("제안 금액") { amountText = suggestedAmount() }
                        .font(.caption)
                }
                TextField(selectedTab == .native ? nativeSymbol() + " 단위" : "토큰 단위(18 소수)", text: $amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
            }

            if selectedTab == .erc20 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("컨트랙트 주소 (자동)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(currentERC20Contract() ?? "이 체인에서는 ERC-20 전송이 비활성화됨")
                        .font(.caption)
                        .foregroundColor(currentERC20Contract() == nil ? .red : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private var sendButton: some View {
        Button(action: performSend) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isLoading ? "전송 중..." : (selectedTab == .native ? "네이티브 전송" : "ERC-20 전송"))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isLoading || !canSend ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading || !canSend)
    }

    private var bottomSendBar: some View {
        VStack(spacing: 0) {
            sendButton
                .padding(.horizontal)
                .padding(.bottom, 10)
        }
        .background(Color(.systemBackground).opacity(0.9))
    }

    private var resultSection: some View {
        Group {
            if let txHash = txHash {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("전송 결과")
                            .font(.headline)
                        Spacer()
                        Button("상세 보기") { showResult = true }
                            .font(.caption)
                    }
                    Text(txHash)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
    }

    private var canSend: Bool {
        guard sdk.isConnected else { return false }
        guard isValidAddress(receiverAddress) else { return false }
        guard !amountText.isEmpty, Decimal(string: amountText) != nil else { return false }
        if selectedTab == .erc20 { return currentERC20Contract() != nil }
        return true
    }

    private func performSend() {
        dismissKeyboard()
        Task { await send() }
    }

    @MainActor
    private func send() async {
        isLoading = true
        errorMessage = nil
        txHash = nil

        do {
            switch selectedTab {
            case .native:
                let tx = try await sdk.sendETH(to: receiverAddress, amount: amountText)
                txHash = tx
            case .erc20:
                guard let contract = currentERC20Contract() else {
                    throw SimpleError("이 체인에서는 ERC-20 전송을 지원하지 않습니다")
                }
                let data = try encodeERC20TransferData(to: receiverAddress, amount: amountText, decimals: 18)
                let params = CrossTransactionParams(to: contract, value: "0", data: data)
                let tx = try await sdk.sendTransaction(params)
                txHash = tx
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func nativeSymbol() -> String {
        sdk.currentChain?.symbol ?? "ETH"
    }

    private func suggestedAmount() -> String {
        guard let chainId = sdk.currentChain?.rawValue else { return "0.001" }
        if chainId == "1" || chainId == "11155111" { return "0.0001" }
        return "1"
    }

    private func currentERC20Contract() -> String? {
        guard let chainId = sdk.currentChain?.rawValue else { return nil }
        return erc20Contracts[chainId]
    }

    private func isValidAddress(_ address: String) -> Bool {
        let pattern = "^0x[0-9a-fA-F]{40}$"
        return address.range(of: pattern, options: .regularExpression) != nil
    }

    private func encodeERC20TransferData(to: String, amount: String, decimals: Int) throws -> String {
        let selector = "a9059cbb"
        let addressNoPrefix = String(to.dropFirst(2)).lowercased()
        guard addressNoPrefix.count == 40 else { throw SimpleError("수신자 주소 형식이 올바르지 않습니다") }

        let amountHex = try amountToUInt256Hex(amount, decimals: decimals)
        let paddedAddress = addressNoPrefix.leftPadded(to: 64)
        let paddedAmount = amountHex.leftPadded(to: 64)
        return "0x" + selector + paddedAddress + paddedAmount
    }

    private func amountToUInt256Hex(_ amount: String, decimals: Int) throws -> String {
        let s = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^\\d*(?:\\.\\d*)?$"
        guard s.range(of: pattern, options: .regularExpression) != nil, !s.isEmpty else {
            throw SimpleError("금액 형식이 올바르지 않습니다")
        }

        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        let intPart = parts.first.map(String.init) ?? "0"
        let fracPart = parts.count > 1 ? String(parts[1]) : ""
        if fracPart.count > decimals { throw SimpleError("소수 자릿수가 너무 큽니다") }
        let paddedFrac = fracPart + String(repeating: "0", count: max(0, decimals - fracPart.count))

        // 결합된 10진 정수 문자열 (앞의 0 제거)
        let combined = (intPart + paddedFrac).drop { $0 == "0" }
        let decimalString = combined.isEmpty ? "0" : String(combined)

        // 10진 문자열 → 16진 문자열로 변환
        return decimalStringToHex(decimalString)
    }

    private var erc20Contracts: [String: String] {
        [
            "612044": "0xe934057Ac314cD9bA9BC17AE2378959fd39Aa2E3", // Cross Testnet
            "612055": "0xe9013a5231BEB721f4F801F2d07516b8ca19d953", // Cross Mainnet
            "1001": "0xd4846dddf83278d10b92bf6c169c5951d6f5abb8"  // Kaia Testnet
        ]
    }
}

private enum SendTab { case native, erc20 }

private struct TabPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct TxResultView: View {
    let txHash: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("트랜잭션 해시")
                        .font(.headline)
                    Text(txHash)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("전송 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("완료") { dismiss() } } }
        }
    }
}

private struct SimpleError: LocalizedError { let message: String; init(_ m: String) { message = m } ; var errorDescription: String? { message } }

private extension String {
    func leftPadded(to length: Int, with char: Character = "0") -> String {
        if count >= length { return self }
        return String(repeating: String(char), count: length - count) + self
    }
}

private func decimalStringToHex(_ decimal: String) -> String {
    let digitsOnly = decimal.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted)
    if digitsOnly == "" || digitsOnly == "0" { return "0" }
    var number = digitsOnly
    var hex = ""
    let hexAlphabet = Array("0123456789abcdef")
    while number != "0" {
        let (q, r) = divideDecimalStringBy16(number)
        hex.append(hexAlphabet[r])
        number = q
    }

#if canImport(UIKit)
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
#endif
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
