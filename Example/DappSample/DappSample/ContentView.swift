//
//  ContentView.swift
//  DappSample
//
//  Created by Chuck on 8/6/25.
//

import SwiftUI
import CrossSDKSwift

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
                Button("Connect Wallet") {
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

#Preview {
    ContentView()
}
