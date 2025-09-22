import SwiftUI
import CrossSDKSwift
import SafariServices

struct SendExampleView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    @State private var selectedTab: SendTab = .native
    @State private var receiverAddress: String = "0x9e68897612dD9A78F8371a2a2e7395Ec8445F6Df"
    @State private var amountText: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var txHash: String?
    @State private var showResult: Bool = false
    
    // Receipt 폴링 관련 상태
    @State private var isWaitingForReceipt: Bool = false
    @State private var transactionReceipt: CrossTransactionReceipt?
    @State private var receiptError: String?
    
    // Safari 관련 상태 - 간단한 구조체로 URL과 표시 상태를 함께 관리
    @State private var safariPresentation: SafariPresentation? = nil
    @State private var showURLAlert: Bool = false
    @State private var alertURL: String = ""
    
    
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
            .alert("블록 스캐너 URL", isPresented: $showURLAlert) {
                Button("복사") {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = alertURL
                    #endif
                }
                Button("시스템 브라우저에서 열기") {
                    if let url = URL(string: alertURL) {
                        #if canImport(UIKit)
                        UIApplication.shared.open(url)
                        #endif
                    }
                }
                Button("닫기", role: .cancel) { }
            } message: {
                Text(alertURL)
            }
            .sheet(isPresented: $showResult) {
                if let txHash = txHash {
                    TxResultView(
                        txHash: txHash,
                        receipt: transactionReceipt,
                        isWaitingForReceipt: isWaitingForReceipt,
                        receiptError: receiptError
                    )
                }
            }
            .sheet(item: $safariPresentation) { presentation in
                SimpleSafariView(url: presentation.url)
                    .onAppear {
                        print("🎯 Safari sheet appeared with URL: \(presentation.url.absoluteString)")
                    }
                    .onDisappear {
                        print("🎯 Safari sheet disappeared")
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
                    
                    // 트랜잭션 해시
                    Text(txHash)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // Receipt 상태 표시
                    receiptStatusView
                }
            }
        }
    }
    
    private var receiptStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("트랜잭션 상태")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // 블록 스캐너 버튼 (txHash가 있으면 항상 표시)
                if txHash != nil {
                    Menu {
                        Button(action: openInBlockScanner) {
                            Label("인앱 브라우저", systemImage: "safari")
                        }
                        Button(action: openInSystemBrowser) {
                            Label("시스템 브라우저", systemImage: "globe")
                        }
                        Button(action: showURLInAlert) {
                            Label("URL 확인", systemImage: "doc.on.doc")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                            Text("블록스캔")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                if isWaitingForReceipt {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("확인 중...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else if let receipt = transactionReceipt {
                    HStack(spacing: 4) {
                        Image(systemName: receipt.receiptStatus == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(receipt.receiptStatus == .success ? .green : .red)
                        Text(receipt.receiptStatus == .success ? "성공" : "실패")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(receipt.receiptStatus == .success ? .green : .red)
                    }
                } else if let error = receiptError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("확인 실패")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Receipt 상세 정보
            if let receipt = transactionReceipt {
                VStack(alignment: .leading, spacing: 4) {
                    if let blockNumber = receipt.blockNumber {
                        Text("블록: \(blockNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("가스 사용: \(receipt.gasUsed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if receipt.receiptStatus == .success {
                        Text("✅ 트랜잭션이 성공적으로 완료되었습니다")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("❌ 트랜잭션이 실패했습니다")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            } else if let error = receiptError {
                Text("오류: \(error)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }

    private var canSend: Bool {
        guard sdk.isConnected else { return false }
        guard isValidAddress(receiverAddress) else { return false }
        guard !amountText.isEmpty, Decimal(string: amountText) != nil else { return false }
        if selectedTab == .erc20 { return currentERC20Contract() != nil }
        return true
    }
    
    /// 현재 선택된 체인의 블록 스캐너 URL을 생성합니다
    private func getBlockScannerURL(for txHash: String) -> URL? {
        guard let selectedChain = sdk.chainManager.currentChain else { 
            print("❌ No current chain selected")
            return nil 
        }
        
        let explorerURL = selectedChain.explorerUrl
        let fullURL = "\(explorerURL)/tx/\(txHash)"
        
        print("🔗 Chain: \(selectedChain.name)")
        print("🔗 Explorer URL: \(explorerURL)")
        print("🔗 Full URL: \(fullURL)")
        
        return URL(string: fullURL)
    }
    
    /// 인앱 브라우저에서 트랜잭션을 확인합니다
    private func openInBlockScanner() {
        guard let hash = txHash,
              let url = getBlockScannerURL(for: hash) else { 
            print("❌ Failed to generate block scanner URL")
            return 
        }
        
        // URL 유효성 추가 검사
        guard url.scheme == "https" || url.scheme == "http" else {
            print("❌ Invalid URL scheme: \(url.scheme ?? "nil")")
            return
        }
        
        print("🌐 Opening block scanner URL in Safari: \(url.absoluteString)")
        print("🔍 URL components - scheme: \(url.scheme ?? "nil"), host: \(url.host ?? "nil"), path: \(url.path)")
        
        // 메인 스레드에서 UI 업데이트 확실히 하기
        DispatchQueue.main.async {
            print("🎯 Creating Safari presentation with URL...")
            self.safariPresentation = SafariPresentation(url: url)
            print("🎯 Safari presentation set: \(self.safariPresentation?.url.absoluteString ?? "nil")")
        }
    }
    
    /// 시스템 브라우저에서 트랜잭션을 확인합니다
    private func openInSystemBrowser() {
        guard let hash = txHash,
              let url = getBlockScannerURL(for: hash) else { 
            print("❌ Failed to generate block scanner URL")
            return 
        }
        
        print("🌐 Opening block scanner URL in system browser: \(url.absoluteString)")
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
    
    /// URL을 Alert로 표시합니다
    private func showURLInAlert() {
        guard let hash = txHash,
              let url = getBlockScannerURL(for: hash) else { 
            print("❌ Failed to generate block scanner URL")
            return 
        }
        
        alertURL = url.absoluteString
        showURLAlert = true
    }

    private func performSend() {
        Task { await send() }
    }

    @MainActor
    private func send() async {
        isLoading = true
        errorMessage = nil
        txHash = nil
        transactionReceipt = nil
        receiptError = nil

        do {
            let tx: String
            
            switch selectedTab {
            case .native:
                tx = try await sdk.sendNative(
                    to: receiverAddress,
                    amount: amountText,
                    customData: CustomData(
                        string: "You are about to send native token.",
                        additional: [
                            "timestamp": ISO8601DateFormatter().string(from: Date())
                        ]
                    )
                )
            case .erc20:
                guard let contract = currentERC20Contract() else {
                    throw SimpleError("이 체인에서는 ERC-20 전송을 지원하지 않습니다")
                }
                let data = try encodeERC20TransferData(to: receiverAddress, amount: amountText, decimals: 18)
                let params = CrossTransactionParams(to: contract, value: "0", data: data)
                tx = try await sdk.sendTransaction(
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
            }
            
            // 트랜잭션 해시 설정
            txHash = tx
            
            // Receipt 폴링 시작
            isLoading = false
            isWaitingForReceipt = true
            
            do {
                print("🔍 Starting receipt polling for tx: \(tx)")
                let receipt = try await sdk.transactionManager.waitForTransactionReceipt(txHash: tx)
                transactionReceipt = receipt
                print("✅ Receipt received: \(receipt.receiptStatus)")
            } catch {
                receiptError = error.localizedDescription
                print("❌ Receipt polling failed: \(error)")
            }
            
            isWaitingForReceipt = false
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
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
        return CrossSDKSwift.shared.utils.isValidAddress(address)
    }

    private func encodeERC20TransferData(to: String, amount: String, decimals: Int) throws -> String {
        do {
            return try CrossSDKSwift.shared.utils.encodeERC20TransferData(to: to, amount: amount, decimals: decimals)
        } catch {
            throw SimpleError(error.localizedDescription)
        }
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
    let receipt: CrossTransactionReceipt?
    let isWaitingForReceipt: Bool
    let receiptError: String?
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 트랜잭션 해시 섹션
                    VStack(alignment: .leading, spacing: 8) {
                        Text("트랜잭션 해시")
                            .font(.headline)
                        Text(txHash)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    
                    // Receipt 상태 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        Text("트랜잭션 상태")
                            .font(.headline)
                        
                        if isWaitingForReceipt {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("블록체인에서 트랜잭션 확인 중...")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        } else if let receipt = receipt {
                            receiptDetailView(receipt)
                        } else if let error = receiptError {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Receipt 조회 실패")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                }
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            Text("Receipt 정보를 기다리는 중...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("전송 결과")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("완료") { dismiss() } } }
        }
    }
    
    private func receiptDetailView(_ receipt: CrossTransactionReceipt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상태 표시
            HStack {
                Image(systemName: receipt.receiptStatus == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(receipt.receiptStatus == .success ? .green : .red)
                    .font(.title2)
                Text(receipt.receiptStatus == .success ? "트랜잭션 성공" : "트랜잭션 실패")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(receipt.receiptStatus == .success ? .green : .red)
            }
            
            // 상세 정보
            VStack(alignment: .leading, spacing: 8) {
                if let blockNumber = receipt.blockNumber {
                    DetailRow(label: "블록 번호", value: blockNumber)
                }
                if let blockHash = receipt.blockHash {
                    DetailRow(label: "블록 해시", value: blockHash)
                }
                DetailRow(label: "가스 사용량", value: receipt.gasUsed)
                DetailRow(label: "누적 가스", value: receipt.cumulativeGasUsed)
                DetailRow(label: "보낸 주소", value: receipt.from)
                if let to = receipt.to {
                    DetailRow(label: "받는 주소", value: to)
                }
                if let contractAddress = receipt.contractAddress {
                    DetailRow(label: "컨트랙트 주소", value: contractAddress)
                }
                
                if !receipt.logs.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("이벤트 로그: \(receipt.logs.count)개")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("트랜잭션에서 \(receipt.logs.count)개의 이벤트가 발생했습니다")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(receipt.receiptStatus == .success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}

private struct SimpleError: LocalizedError { let message: String; init(_ m: String) { message = m } ; var errorDescription: String? { message } }


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

// MARK: - Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        print("🎯 Creating Safari view for URL: \(url.absoluteString)")
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = UIColor.systemBlue
        safari.dismissButtonStyle = .close
        safari.delegate = context.coordinator
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            print("🎯 Safari initial load completed: \(didLoadSuccessfully ? "Success" : "Failed")")
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            print("🎯 Safari view controller finished")
        }
    }
}

// MARK: - Simple Safari View (direct presentation)
struct SimpleSafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        print("🎯 Creating simple Safari view for URL: \(url.absoluteString)")
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = UIColor.systemBlue
        safari.dismissButtonStyle = .close
        safari.delegate = context.coordinator
        return safari
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> SafariCoordinator {
        SafariCoordinator()
    }
    
    class SafariCoordinator: NSObject, SFSafariViewControllerDelegate {
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            print("🎯 Simple Safari initial load completed: \(didLoadSuccessfully ? "Success" : "Failed")")
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            print("🎯 Simple Safari view controller finished")
        }
    }
}

// MARK: - Safari Navigation View (for better presentation)
struct SafariNavigationView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            SafariView(url: url)
                .navigationTitle("블록 스캐너")
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

// MARK: - Safari Presentation Model
struct SafariPresentation: Identifiable {
    let id = UUID()
    let url: URL
    
    init(url: URL) {
        self.url = url
        print("🎯 SafariPresentation created with URL: \(url.absoluteString)")
    }
}
