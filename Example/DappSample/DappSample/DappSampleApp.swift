//
//  DappSampleApp.swift
//  DappSample
//
//  Created by Chuck on 8/6/25.
//

import SwiftUI
import CrossSDKSwift
import CrossAppKit
import WalletConnectSign

@main
struct DappSampleApp: App {

    init() {
        // 새로운 CrossSDKSwift API를 사용한 간단한 설정
        setupSDK()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func setupSDK() {
        // 새로운 CrossSDKSwift의 간단한 설정 API 사용
        CrossSDKSwift.shared.configure(
            projectId: "96ee29d02db94e2d92c41d6bcbfeec44",
            groupIdentifier: "group.com.nexus.DappSample",
            appName: "Cross DappSample",
            appDescription: "Cross SDK Sample App using new CrossSDKSwift",
            appUrl: "https://example.com/dappsample",
            iconUrls: ["https://contents.crosstoken.io/img/sample_app_circle_icon.png"],
            redirectNative: "dappsample://",
            redirectUniversal: "https://example.com/dappsample/redirect",
            supportedChains: [.crossMainnet, .crossTestnet, .bscMainnet, .kaiaMainnet, .ethereum]
        )

        print("✅ CrossSDKSwift 설정 완료!")
    }
    
    private func handleIncomingURL(_ url: URL) {
        print ("?!! incoming url: \(url)")
    }
}
