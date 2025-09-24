//
//  ContentView.swift
//  DappSample
//
//  Created by Chuck on 8/6/25.
//

import SwiftUI
import CrossSDKSwift

#if canImport(QRCode)
import QRCode
#endif

struct ContentView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                
                Text("Cross SDK DappSample")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Now using new CrossSDKSwift v\(CrossSDKSwift.version)! 🚀")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                // 연결 상태 표시
                ConnectionStatusView()
                
                // 지갑 연결/해제 버튼
                WalletConnectionView()
                
                // ReownAppKit UI 사용 연결 버튼
                ConnectWalletViaAppKitUI(isConnected: sdk.isConnected)
                
                // 체인 변경 버튼들
                if sdk.isConnected {
                    ChainSwitchView()
                }
                
                // 서명 예제 뷰로 이동
                if sdk.isConnected {
                    NavigationLink(destination: SigningExampleView()) {
                        HStack {
                            Image(systemName: "signature")
                            Text("서명 예제 테스트")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    // 전송 예제 뷰로 이동
                    NavigationLink(destination: SendExampleView()) {
                        HStack {
                            Image(systemName: "paperplane")
                            Text("전송 예제 테스트")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // 잔액 조회 예제 뷰로 이동
                    NavigationLink(destination: BalanceExampleView()) {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                            Text("잔액 조회 예제")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("CrossSDK DappSample")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func testSendETH() async {
        do {
            // 테스트용 주소 (실제로는 사용자 입력을 받아야 함)
            let testAddress = "0x742d35Cc6634C0532925a3b8D2C0b5C6C8b9c3f7"
            let txHash: String = try await sdk.sendNative(to: testAddress, amount: "0.001")
            print("✅ ETH send successful: \(txHash)")
        } catch {
            print("❌ ETH send error: \(error.localizedDescription)")
        }
    }
}

// MARK: - 연결 상태 표시 뷰
struct ConnectionStatusView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    var body: some View {
        VStack(spacing: 8) {
            switch sdk.detailedConnectionState {
            case .idle:
                Text("🔵 Ready to connect")
                    .foregroundColor(.blue)
            case .disconnected:
                Text("🔴 Disconnected")
                    .foregroundColor(.red)
            case .connecting:
                Text("🟡 Connecting...")
                    .foregroundColor(.orange)
            case .authenticating:
                Text("🟠 Authenticating...")
                    .foregroundColor(.orange)
            case .connected(let wallet):
                VStack(spacing: 4) {
                    Text("🟢 Connected")
                        .foregroundColor(.green)
                    Text("Address: \(formatAddress(wallet.address))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text("Chain:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(getCurrentChainName())
                            .font(.caption)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        // 체인이 변경 중인지 표시
                        if isChainSwitching() {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .rotationEffect(.degrees(isChainSwitching() ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isChainSwitching())
                        }
                    }
                }
            case .error(let error):
                Text("🔴 Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private func formatAddress(_ address: String) -> String {
        return CrossSDKSwift.shared.utils.formatAddress(address)
    }
    private func getCurrentChainName() -> String {
        // 현재 선택된 체인이 있으면 그것을 우선 사용
        if let currentChain = sdk.currentChain {
            return currentChain.name
        }
        // 현재 선택된 체인이 없으면 연결된 지갑의 체인 정보 사용
        if case .connected(let wallet) = sdk.detailedConnectionState {
            return wallet.chain.name
        }
        return "Unknown"
    }
    private func isChainSwitching() -> Bool {
        // 현재 선택된 체인과 연결된 지갑의 체인이 다르면 체인 변경 중
        guard let currentChain = sdk.currentChain else { return false }
        if case .connected(let wallet) = sdk.detailedConnectionState {
            return currentChain.rawValue != wallet.chain.rawValue
        }
        return false
    }
}

// MARK: - 지갑 연결 뷰
struct WalletConnectionView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared
    @State private var showQRCode = false
    @State private var connectURL: String?
    @State private var isGeneratingURL = false

    var body: some View {
        VStack(spacing: 12) {
            if sdk.isConnected {
                Button("Disconnect Wallet") {
                    Task {
                        do {
                            try await sdk.disconnectWallet()
                        } catch {
                            print("❌ Disconnect error: \(error.localizedDescription)")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(spacing: 12) {
                    // 기존 연결 버튼
                    Button("Connect Wallet (Direct)") {
                        print("🎯 DappSample: Connect Wallet button pressed")
                        Task {
                            do {
                                print("🎯 DappSample: Calling sdk.connectWallet()")
                                try await sdk.connectWallet()
                                print("🎯 DappSample: sdk.connectWallet() completed")
                            } catch {
                                print("❌ Connect error: \(error.localizedDescription)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // QR 코드 연결 버튼
                    Button(isGeneratingURL ? "Generating QR..." : "Connect with QR") {
                        connectWithQRCode()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.blue)
                    .disabled(isGeneratingURL)
                    
                    Text("또는")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // QR 코드만 표시하는 버튼
                    Button("Show QR Code Only") {
                        generateQRCode()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .disabled(isGeneratingURL)
                }
            }
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeView(url: connectURL ?? "")
        }
    }
    
    private func connectWithQRCode() {
        print("🎯 DappSample: Connect with QR button pressed")
        isGeneratingURL = true
        Task {
            do {
                // URL 생성 및 연결 상태 업데이트
                let url = try await sdk.generateConnectURL()
                await MainActor.run {
                    connectURL = url
                    showQRCode = true
                    isGeneratingURL = false
                }
                print("🎯 Generated QR URL for connection: \(url)")
                print("🎯 QR Code modal will be shown - user can scan to connect")
            } catch {
                await MainActor.run {
                    isGeneratingURL = false
                }
                print("❌ QR connection error: \(error.localizedDescription)")
            }
        }
    }
    
    private func generateQRCode() {
        isGeneratingURL = true
        Task {
            do {
                let url = try await sdk.generateConnectURL()
                await MainActor.run {
                    connectURL = url
                    showQRCode = true
                    isGeneratingURL = false
                }
                print("🎯 Generated QR URL: \(url)")
            } catch {
                await MainActor.run {
                    isGeneratingURL = false
                }
                print("❌ QR generation error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 체인 변경 뷰
struct ChainSwitchView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared
    @State private var showingChainSelection = false

    var body: some View {
        VStack(spacing: 8) {
            Text("Current Chain")
                .font(.caption)
                .foregroundColor(.secondary)
            Button(action: {
                showingChainSelection = true
            }) {
                HStack {
                    Text(sdk.currentChain?.name ?? "Select Chain")
                        .font(.system(size: 16, weight: .medium))

                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
            .actionSheet(isPresented: $showingChainSelection) {
                createChainSelectionActionSheet()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private func createChainSelectionActionSheet() -> ActionSheet {
        var buttons: [ActionSheet.Button] = []
        // 각 체인에 대한 버튼 추가
        for chain in sdk.supportedChains {
            let isCurrentChain = sdk.currentChain == chain
            let title = isCurrentChain ? "✓ \(chain.name)" : chain.name
            buttons.append(.default(Text(title)) {
                if !isCurrentChain {
                    Task {
                        sdk.switchChain(to: chain)
                    }
                }
            })
        }

        // 취소 버튼 추가
        buttons.append(.cancel())
        return ActionSheet(
            title: Text("Select Chain"),
            message: Text("Choose a blockchain to switch to"),
            buttons: buttons
        )
    }
}

// MARK: - ReownAppKit UI 연결 버튼
struct ConnectWalletViaAppKitUI: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared
    let isConnected: Bool
    init(isConnected: Bool) {
        self.isConnected = isConnected
    }
    var body: some View {
        VStack(spacing: 8) {
            Text("Use AppKit UI")
                .font(.caption)
                .foregroundColor(.secondary)
            Button(isConnected ? "More Account info via AppKit" : "Connect Wallet via AppKit") {
                // ReownAppKit의 내장 UI 모달 표시
                print("🎯 DappSample: Connect Wallet via UI Kit button pressed")
                sdk.appKitPresent()
                print("🎯 DappSample: AppKit.present() called")
            }
            .buttonStyle(.bordered)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 즉시 체인 변경 UI
struct ImmediateChainSwitchView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared
    @State private var showingChainSelection = false

    var body: some View {
        VStack(spacing: 12) {
            // 현재 체인 표시
            HStack {
                Text("Current Chain:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(sdk.currentChain?.name ?? "None")
                    .font(.headline)
                    .foregroundColor(.primary)

                // 즉시 변경 표시
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)

                Spacer()
            }

            // 체인 선택 버튼
            Button("⚡ Change Chain Instantly") {
                showingChainSelection = true
            }
            .buttonStyle(.borderedProminent)
            .foregroundColor(.white)
            .actionSheet(isPresented: $showingChainSelection) {
                createChainSelectionActionSheet()
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }

    private func createChainSelectionActionSheet() -> ActionSheet {
        let buttons = CrossChain.allCases.map { chain in
            ActionSheet.Button.default(Text(chain.name)) {
                // ⚡ 즉시 체인 변경 (지갑 승인 불필요, 지갑도 자동으로 따라감)
                sdk.switchChain(to: chain)
            }
        }

        return ActionSheet(
            title: Text("Select Chain Instantly"),
            message: Text("Chain will change immediately. Wallet will auto-switch."),
            buttons: buttons + [.cancel()]
        )
    }
}

// MARK: - QR 코드 표시 뷰
struct QRCodeView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var sdk = CrossSDKSwift.shared
    @State private var connectionCheckTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 연결 상태에 따른 제목 변경
                if sdk.isConnected {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("연결 완료!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("지갑이 성공적으로 연결되었습니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("지갑 연결 QR 코드")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("CROSSx 지갑으로 이 QR 코드를 스캔하세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if !sdk.isConnected {
                    // QR 코드 표시
                    qrCodeImage
                        .frame(width: 250, height: 250)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    // 연결 대기 상태 표시
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("연결 대기 중...")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 8)
                    
                    // URL 텍스트 (디버깅용)
                    VStack(spacing: 8) {
                        Text("연결 URL:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(url)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .lineLimit(3)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 연결 완료 시 닫기 버튼
                if sdk.isConnected {
                    Button("완료") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }
            }
            .padding()
            .navigationTitle("QR 연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                startConnectionMonitoring()
            }
            .onDisappear {
                stopConnectionMonitoring()
            }
        }
    }
    
    @ViewBuilder
    private var qrCodeImage: some View {
        #if canImport(QRCode)
        if let qrImage = generateQRCode(from: url) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            qrCodeFallback
        }
        #else
        qrCodeFallback
        #endif
    }
    
    private var qrCodeFallback: some View {
        VStack(spacing: 12) {
            Image(systemName: "qrcode")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("QR 코드를 생성할 수 없습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func startConnectionMonitoring() {
        print("🎯 QRCodeView: Starting connection monitoring")
        // 연결 상태 변화 감지를 위한 타이머는 필요 없음 - @ObservedObject가 자동으로 처리
        // 하지만 연결 완료 시 자동 닫기를 위한 딜레이 추가
        connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if sdk.isConnected {
                print("🎯 QRCodeView: Connection detected - will auto-dismiss in 2 seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
                stopConnectionMonitoring()
            }
        }
    }
    
    private func stopConnectionMonitoring() {
        print("🎯 QRCodeView: Stopping connection monitoring")
        connectionCheckTimer?.invalidate()
        connectionCheckTimer = nil
    }
    
    #if canImport(QRCode)
    private func generateQRCode(from string: String) -> UIImage? {
        let doc = QRCode.Document(
            utf8String: string,
            errorCorrection: .medium
        )
        
        // QR 코드 스타일 설정
        doc.design.additionalQuietZonePixels = 2
        doc.design.style.eye = QRCode.FillStyle.Solid(UIColor.black.cgColor)
        doc.design.style.pupil = QRCode.FillStyle.Solid(UIColor.black.cgColor)
        doc.design.style.onPixels = QRCode.FillStyle.Solid(UIColor.black.cgColor)
        doc.design.style.background = QRCode.FillStyle.Solid(UIColor.white.cgColor)
        
        guard let cgImage = try? doc.cgImage(CGSize(width: 500, height: 500)) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    #endif
}

#Preview {
    ContentView()
}
