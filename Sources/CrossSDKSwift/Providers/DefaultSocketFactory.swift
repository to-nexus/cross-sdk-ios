//
//  DefaultSocketFactory.swift
//  CrossSDKSwift
//
//  Created by CrossSDK Team
//

import Foundation
import Combine
import WalletConnectRelay

#if os(iOS)
import UIKit
#elseif os(macOS)
import CrossAppKit
import IOKit.pwr_mgt
#endif
/// Default implementation of WebSocketFactory
public struct DefaultSocketFactory: WebSocketFactory {
    private let networkMonitor: NetworkMonitoring
    
    /// Create a WebSocket connection
    /// - Parameter url: WebSocket URL
    /// - Returns: WebSocketConnecting instance
    public func create(with url: URL) -> WebSocketConnecting {
        return DefaultWebSocket(url: url, networkMonitor: networkMonitor)
    }
    
    /// Public initializer
    public init(networkMonitor: NetworkMonitoring = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
    }
}

/// Default WebSocket implementation
final class DefaultWebSocket: NSObject, WebSocketConnecting {
    var request: URLRequest
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private var pingTimer: Timer?
    private let pingInterval: TimeInterval = 30.0
    private var shouldReconnect = true
    private var reconnectDelay: TimeInterval = 5.0
    private let networkMonitor: NetworkMonitoring
    private var networkCancellable: AnyCancellable?
    private var isHandshakeCompleted: Bool = false
    
    var isConnected: Bool {
        return webSocketTask?.state == .running
    }
    
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?
    
    init(url: URL, networkMonitor: NetworkMonitoring = NetworkMonitor()) {
        self.request = URLRequest(url: url)
        self.session = URLSession(configuration: .default)
        self.networkMonitor = networkMonitor
        super.init()
//        observeAppLifecycle()
        observeNetwork()
    }
    
    func connect() {
        guard webSocketTask == nil else { return }
        shouldReconnect = true
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        listen()
        startPingTimer()
        self.onConnect?()
    }
    
    func disconnect() {
        shouldReconnect = false
        stopPingTimer()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        onDisconnect?(nil)
    }
    
    func write(string: String, completion: (() -> Void)?) {
        print("### [DefaultWebSocket] send: \(string)")
        let message = URLSessionWebSocketTask.Message.string(string)
        webSocketTask?.send(message) { _ in
            completion?()
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                print("### [DefaultWebSocket] rcv: \(message)")
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.onText?(text)
                    }
                case .data(let data):
                    if let string = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self?.onText?(string)
                        }
                    }
                @unknown default:
                    break
                }
                self?.listen()
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.stopPingTimer()
                    self?.webSocketTask = nil
                    self?.onDisconnect?(error)
                    self?.reconnectIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Ping/Pong Management
    
    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        guard isConnected else {
            stopPingTimer()
            return
        }
        
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.stopPingTimer()
                    self?.webSocketTask = nil
                    self?.onDisconnect?(error)
                    self?.reconnectIfNeeded()
                }
            }
        }
    }
    
    private func reconnectIfNeeded() {
        guard shouldReconnect else { return }
        guard !isConnected, webSocketTask == nil else { return }

        // 재연결 백오프 전략 적용
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            guard let self = self else { return }
            if !self.isConnected && self.webSocketTask == nil {
                self.connect()
            }
        }
    }
    //
    // MARK: - Network Monitoring
    //
    private func observeNetwork() {
        networkCancellable = networkMonitor.networkConnectionStatusPublisher
            .sink { [weak self] status in
                if status == .connected {
                    DispatchQueue.main.async {
                        self?.reconnectIfNeeded()
                    }
                }
            }
    }
    //
    // MARK: - App Lifecycle Observing
    //
    private func observeAppLifecycle() {
#if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
#elseif os(macOS)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
#endif
    }
    
    ///
    /// for App life cycle
    ///
    @objc private func appWillEnterForeground() {
        reconnectIfNeeded()
    }
    
    @objc private func appDidEnterBackground() {
//        disconnect()
    }
    
    ///
    /// for Mac life cycle
    ///
    @objc private func appDidWake() {
        reconnectIfNeeded()
    }
    
    @objc private func appWillSleep() {
        disconnect()
    }
    
    deinit {
        networkCancellable?.cancel()
#if os(iOS)
        NotificationCenter.default.removeObserver(self)
#elseif os(macOS)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
#endif
    }
}
