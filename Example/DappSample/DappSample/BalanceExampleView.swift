import SwiftUI
import CrossSDKSwift
import Commons
import WalletConnectUtils

struct BalanceExampleView: View {
    @ObservedObject var crossSDK = CrossSDKSwift.shared
    
    // Balance states
    @State private var nativeBalance: String = "0.0"
    @State private var erc20Balance: String = "0"
    @State private var isLoadingNative: Bool = false
    @State private var isLoadingERC20: Bool = false
    
    // Native token info
    @State private var nativeSymbol: String = "CROSS"
    @State private var nativeDecimals: Int = 18
    
    // ERC-20 token configuration
    @State private var tokenAddress: String = "0xe9013a5231beb721f4f801f2d07516b8ca19d953"
    @State private var tokenSymbol: String = "ZENY"
    @State private var tokenDecimals: Int = 18
    @State private var isLoadingTokenInfo: Bool = false
    
    // Error states
    @State private var nativeError: String?
    @State private var erc20Error: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                
                if crossSDK.isConnected {
                    connectedAccountSection
                    nativeBalanceSection
                    erc20ConfigSection
                    erc20BalanceSection
                } else {
                    disconnectedSection
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("잔액 조회")
        .onAppear {
            updateNativeTokenInfo()
            if crossSDK.isConnected {
                loadBalances()
            }
        }
        .onChange(of: crossSDK.currentChain) { _ in
            updateNativeTokenInfo()
            if crossSDK.isConnected {
                loadBalances()
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("💰 잔액 조회 예제")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Native Coin과 ERC-20 토큰의 잔액을 조회합니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var connectedAccountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("연결된 계정")
                .font(.headline)
            
            if case .connected(let wallet) = crossSDK.detailedConnectionState {
                HStack {
                    Text("주소:")
                        .foregroundColor(.secondary)
                    Text(CrossSDKSwift.shared.utils.formatAddress(wallet.address))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("체인:")
                        .foregroundColor(.secondary)
                    Text(crossSDK.currentChain?.name ?? "Unknown")
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var nativeBalanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💎 Native Balance")
                    .font(.headline)
                Spacer()
                Button("새로고침") {
                    loadNativeBalance()
                }
                .disabled(isLoadingNative)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(nativeSymbol) 잔액")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isLoadingNative {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("조회 중...")
                                .font(.system(.body, design: .monospaced))
                        }
                    } else {
                        Text("\(nativeBalance) \(nativeSymbol)")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
            }
            
            if let error = nativeError {
                Text("❌ \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var erc20ConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔧 ERC-20 토큰 설정")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("토큰 주소:")
                        .frame(width: 80, alignment: .leading)
                    TextField("0x...", text: $tokenAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.caption, design: .monospaced))
                }
                
                HStack {
                    Text("심볼:")
                        .frame(width: 80, alignment: .leading)
                    TextField("USDC", text: $tokenSymbol)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("소수점:")
                        .frame(width: 80, alignment: .leading)
                    TextField("6", value: $tokenDecimals, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }
            
            HStack {
                Button("ZENY 설정") {
                    setZENYToken()
                }
                .buttonStyle(.bordered)
                
                Button("MGT 설정") {
                    setMGTToken()
                }
                .buttonStyle(.bordered)
                
                Button("토큰 정보 조회") {
                    loadTokenMetadata()
                }
                .buttonStyle(.borderedProminent)
                .disabled(tokenAddress.isEmpty || isLoadingTokenInfo)
                
                Spacer()
            }
            
            if isLoadingTokenInfo {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("토큰 정보 조회 중...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var erc20BalanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🪙 ERC-20 Balance")
                    .font(.headline)
                Spacer()
                Button("조회") {
                    loadERC20Balance()
                }
                .disabled(isLoadingERC20 || tokenAddress.isEmpty)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(tokenSymbol) 잔액")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isLoadingERC20 {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("조회 중...")
                                .font(.system(.body, design: .monospaced))
                        }
                    } else {
                        Text("\(formatTokenBalance(erc20Balance)) \(tokenSymbol)")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
            }
            
            if let error = erc20Error {
                Text("❌ \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var disconnectedSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("지갑을 먼저 연결해주세요")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("잔액 조회를 위해서는 지갑 연결이 필요합니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func updateNativeTokenInfo() {
        guard let currentChain = crossSDK.currentChain else {
            nativeSymbol = "CROSS"
            nativeDecimals = 18
            return
        }
        
        switch currentChain {
        default:
            nativeSymbol = currentChain.symbol
            nativeDecimals = currentChain.decimals
        }
    }
    
    private func loadBalances() {
        loadNativeBalance()
        if !tokenAddress.isEmpty {
            loadERC20Balance()
        }
    }
    
    private func loadTokenMetadata() {
        guard !tokenAddress.isEmpty else { return }
        
        isLoadingTokenInfo = true
        
        Task {
            do {
                // 병렬로 symbol과 decimals 조회
                async let symbolTask = crossSDK.transactionManager.readContract(
                    contractAddress: tokenAddress,
                    methodName: "symbol",
                    abi: "symbol()"
                )
                async let decimalsTask = crossSDK.transactionManager.readContract(
                    contractAddress: tokenAddress,
                    methodName: "decimals",
                    abi: "decimals()"
                )
                
                let symbolHex = try await symbolTask
                let decimalsHex = try await decimalsTask
                
                // Symbol 디코딩 (bytes32 또는 string)
                let decodedSymbol = decodeStringFromHex(symbolHex)
                
                // Decimals 디코딩
                let decimalsDecimal = hexToDecimal(decimalsHex)
                let decodedDecimals = NSDecimalNumber(decimal: decimalsDecimal).intValue
                
                await MainActor.run {
                    self.tokenSymbol = decodedSymbol.isEmpty ? "TOKEN" : decodedSymbol
                    self.tokenDecimals = max(0, min(18, decodedDecimals)) // 0-18 범위로 제한
                    self.isLoadingTokenInfo = false
                }
                
                print("✅ Token metadata loaded: \(decodedSymbol) (\(decodedDecimals) decimals)")
                
            } catch {
                await MainActor.run {
                    self.isLoadingTokenInfo = false
                }
                print("❌ Failed to load token metadata: \(error)")
            }
        }
    }
    
    private func loadNativeBalance() {
        guard crossSDK.isConnected else { return }
        
        isLoadingNative = true
        nativeError = nil
        
        Task {
            do {
                let balanceWei = try await crossSDK.fetchNativeBalance()
                let formattedBalance = formatNativeBalance(Decimal(string: balanceWei) ?? Decimal(0))
                
                await MainActor.run {
                    self.nativeBalance = formattedBalance
                    self.isLoadingNative = false
                }
                
                print("✅ Native balance loaded: \(formattedBalance) \(nativeSymbol)")
                
            } catch {
                await MainActor.run {
                    self.nativeError = error.localizedDescription
                    self.isLoadingNative = false
                }
                print("❌ Failed to load native balance: \(error)")
            }
        }
    }
    
    private func loadERC20Balance() {
        guard crossSDK.isConnected, !tokenAddress.isEmpty else { 
            print("❌ Cannot load ERC-20 balance: connected=\(crossSDK.isConnected), tokenAddress='\(tokenAddress)'")
            return 
        }
        
        print("🔄 Loading ERC-20 balance for \(tokenSymbol) at \(tokenAddress)")
        
        isLoadingERC20 = true
        erc20Error = nil
        
        Task {
            do {
                let balanceRaw = try await crossSDK.fetchERC20Balance(contractAddress: tokenAddress)
                
                await MainActor.run {
                    self.erc20Balance = balanceRaw
                    self.isLoadingERC20 = false
                }
                
                print("✅ ERC-20 balance loaded: \(balanceRaw) \(tokenSymbol) (raw balance)")
                
            } catch {
                await MainActor.run {
                    self.erc20Error = error.localizedDescription
                    self.isLoadingERC20 = false
                }
                print("❌ Failed to load ERC-20 balance for \(tokenSymbol): \(error)")
            }
        }
    }
    
    private func setZENYToken() {
        // Ethereum Mainnet USDC
        tokenAddress = "0xe9013a5231beb721f4f801f2d07516b8ca19d953"
        tokenSymbol = "ZENY"
        tokenDecimals = 18
        
        // 토큰 설정 후 자동으로 잔액 조회
        loadERC20Balance()
    }
    
    private func setMGTToken() {
        // Ethereum Mainnet DAI
        tokenAddress = "0x5b1579a758916560f00212b78a7af728eaa0ffa9"
        tokenSymbol = "MGT"
        tokenDecimals = 18
        
        // 토큰 설정 후 자동으로 잔액 조회
        loadERC20Balance()
    }
    
    private func getCurrentRPCURL() -> String {
        // 현재 체인의 RPC URL을 가져오거나 기본값 사용
        guard let rpcUrl = crossSDK.currentChain?.rpcUrl else {
            return "https://eth.llamarpc.com"
        }
        return rpcUrl
    }
    
    private func hexToDecimal(_ hex: String) -> Decimal {
        return CrossSDKSwift.shared.utils.hexToDecimal(hex)
    }
    
    private func formatNativeBalance(_ wei: Decimal) -> String {
        let divisor = pow(Decimal(10), nativeDecimals)
        let balance = wei / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "0"
    }
    
    private func decodeStringFromHex(_ hex: String) -> String {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        
        // 빈 응답이거나 0인 경우
        if cleanHex.isEmpty || cleanHex.allSatisfy({ $0 == "0" }) {
            return ""
        }
        
        // ABI 인코딩된 string 디코딩
        if cleanHex.count >= 128 {
            // 첫 32바이트는 오프셋, 다음 32바이트는 길이
            let lengthHex = String(cleanHex.dropFirst(64).prefix(64))
            if let length = Int(lengthHex, radix: 16), length > 0 && length <= 32 {
                let dataHex = String(cleanHex.dropFirst(128).prefix(length * 2))
                let data = Data(hex: dataHex)
                return String(data: data, encoding: .utf8) ?? ""
            }
        }
        
        // bytes32 형태로 저장된 경우 (마지막 null 바이트들 제거)
        if cleanHex.count == 64 {
            let trimmed = cleanHex.replacingOccurrences(of: "00+$", with: "", options: .regularExpression)
            let data = Data(hex: trimmed)
            return String(data: data, encoding: .utf8) ?? ""
        }
        
        return ""
    }
    
    private func formatTokenBalance(_ balance: String) -> String {
        guard let balanceDecimal = Decimal(string: balance) else { return balance }
        
        let divisor = pow(Decimal(10), tokenDecimals)
        let formatted = balanceDecimal / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = min(tokenDecimals, 6)
        
        return formatter.string(from: NSDecimalNumber(decimal: formatted)) ?? balance
    }
}

#Preview {
    NavigationView {
        BalanceExampleView()
    }
}
