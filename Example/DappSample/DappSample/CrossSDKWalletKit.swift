//
//  CrossSDKWalletKit.swift
//  DappSample
//
//  Updated for new CrossSDKSwift API
//

import SwiftUI
import CrossSDKSwift

/// All-in-one wallet connection component using new CrossSDKSwift
/// Provides connect button, network selection, and account info in one component
struct CrossSDKWalletKit: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    private let showNetworkButton: Bool
    private let showAccountInfo: Bool

    /// Initialize CrossSDKWalletKit
    /// - Parameters:
    ///   - showNetworkButton: Whether to show network selection button
    ///   - showAccountInfo: Whether to show account information
    init(
        showNetworkButton: Bool = true,
        showAccountInfo: Bool = true
    ) {
        self.showNetworkButton = showNetworkButton
        self.showAccountInfo = showAccountInfo
    }

    var body: some View {
        VStack(spacing: 12) {
            // Main connect/disconnect button
            if sdk.isConnected {
                Button("Disconnect") {
                    Task {
                        try? await sdk.disconnectWallet()
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Connect Wallet") {
                    Task {
                        try? await sdk.connectWallet()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            // Network selection (if enabled and connected)
            if showNetworkButton && sdk.isConnected {
                CrossSDKNetworkSelector()
            }

            // Account information (if enabled and connected)
            if showAccountInfo, let wallet = sdk.connectedWallet {
                CrossSDKAccountInfo(wallet: wallet)
            }
        }
    }
}

/// Account information display component
struct CrossSDKAccountInfo: View {
    let wallet: CrossWallet

    var body: some View {
        VStack(spacing: 4) {
            Text("Connected")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(formatAddress(wallet.address))
                .font(.caption)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)

            Text("Chain: \(wallet.chain.name)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

/// Network selector component
struct CrossSDKNetworkSelector: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    var body: some View {
        Menu {
            ForEach(sdk.supportedChains, id: \.self) { chain in
                Button(action: {
                    Task {
                        try? await sdk.switchChain(to: chain)
                    }
                }) {
                    HStack {
                        Text(chain.name)
                        if sdk.currentChain == chain {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(sdk.currentChain?.name ?? "Select Chain")
                Image(systemName: "chevron.down")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Convenience Components

/// Simple connect button with CrossSDK styling
struct CrossSDKConnectButton: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    var body: some View {
        Button(sdk.isConnected ? "Disconnect" : "Connect") {
            Task {
                if sdk.isConnected {
                    try? await sdk.disconnectWallet()
                } else {
                    try? await sdk.connectWallet()
                }
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

/// Simple network button with CrossSDK styling
struct CrossSDKNetworkButton: View {
    var body: some View {
        CrossSDKNetworkSelector()
    }
}

// MARK: - Preview
#if DEBUG
struct CrossSDKWalletKit_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CrossSDKWalletKit()

            CrossSDKWalletKit(showNetworkButton: false)

            CrossSDKWalletKit(showAccountInfo: false)

            Divider()

            CrossSDKConnectButton()

            CrossSDKNetworkButton()
        }
        .padding()
    }
}
#endif
