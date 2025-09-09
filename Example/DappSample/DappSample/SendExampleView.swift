import SwiftUI
import CrossSDKSwift

struct SendExampleView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    @State private var selectedTab: SendTab = .native
    @State private var receiverAddress: String = "0x9e68897612dD9A78F8371a2a2e7395Ec8445F6Df"
    @State private var amountText: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var txHash: String?
    @State private var showResult: Bool = false
    
    // Balance fetching states
    @State private var currentBalance: String = "0"
    @State private var isLoadingBalance: Bool = false

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
            .dismissKeyboardOnInteract()
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
                currentBalance = "0" // 탭 변경시 잔액 초기화
            }
            TabPill(title: "ERC-20 전송", isSelected: selectedTab == .erc20) {
                selectedTab = .erc20
                currentBalance = "0" // 탭 변경시 잔액 초기화
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
                    Button(action: fetchCurrentBalance) {
                        HStack(spacing: 4) {
                            if isLoadingBalance {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                            Text(isLoadingBalance ? "조회 중..." : "잔액 조회")
                        }
                    }
                    .font(.caption)
                    .disabled(isLoadingBalance || !sdk.isConnected)
                }
                TextField(selectedTab == .native ? nativeSymbol() + " 단위" : "토큰 단위(18 소수)", text: $amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                
                if !currentBalance.isEmpty && currentBalance != "0" {
                    HStack {
                        Text("현재 잔액:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(formatBalance(currentBalance)) \(selectedTab == .native ? nativeSymbol() : "토큰")")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Button("전액") {
                            amountText = formatBalance(currentBalance)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
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
                let tx = try await sdk.sendNative(
                    to: receiverAddress,
                    amount: amountText,
                    customData: CustomData(
                        string: "You are about to send native token.",
                        additional: [
                            "timestamp": ISO8601DateFormatter().string(from: Date())
                        ]
                    )
                )
                txHash = tx
            case .erc20:
                guard let contract = currentERC20Contract() else {
                    throw SimpleError("이 체인에서는 ERC-20 전송을 지원하지 않습니다")
                }
                let data = try encodeERC20TransferData(to: receiverAddress, amount: amountText, decimals: 18)
                let params = CrossTransactionParams(to: contract, value: "0", data: data)
                let tx = try await sdk.sendTransaction(
                    params,
                    customData: CustomData(
                        object: [
                            "activity": "You are about to send custom transaction to the contract.",
                            "currentFormat": "This is a JSON formatted custom data.",
                            "providedFormat": "Plain text(string), HTML(string), JSON(key value object) are supported.",
                            "txTime": ISO8601DateFormatter().string(from: Date())
                        ]
                    )
                )
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

    private func fetchCurrentBalance() {
        guard sdk.isConnected else { return }
        
        isLoadingBalance = true
        
        Task {
            do {
                let balance: String
                
                if selectedTab == .native {
                    // Native 토큰 잔액 조회
                    balance = try await sdk.fetchNativeBalance()
                } else {
                    // ERC-20 토큰 잔액 조회
                    guard let contractAddress = currentERC20Contract() else {
                        throw SimpleError("이 체인에서는 ERC-20 전송이 지원되지 않습니다")
                    }
                    balance = try await sdk.fetchERC20Balance(contractAddress: contractAddress)
                }
                
                await MainActor.run {
                    self.currentBalance = balance
                    self.isLoadingBalance = false
                }
                
                print("✅ Balance loaded: \(balance) \(selectedTab == .native ? nativeSymbol() : "토큰")")
                
            } catch {
                await MainActor.run {
                    self.isLoadingBalance = false
                    self.errorMessage = error.localizedDescription
                }
                print("❌ Failed to load balance: \(error)")
            }
        }
    }
    
    private func formatBalance(_ balance: String) -> String {
        guard let balanceDecimal = Decimal(string: balance) else { return balance }
        
        let decimals = selectedTab == .native ? (sdk.currentChain?.decimals ?? 18) : 18
        let divisor = pow(Decimal(10), decimals)
        let formatted = balanceDecimal / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        
        return formatter.string(from: NSDecimalNumber(decimal: formatted)) ?? "0"
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

#if canImport(UIKit)
import UIKit
extension View {
    @ViewBuilder
    func dismissKeyboardOnScroll() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.interactively)
        } else {
            self.gesture(DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            })
        }
    }
}
#else
extension View {
    @ViewBuilder
    func dismissKeyboardOnScroll() -> some View { self }
}
#endif
