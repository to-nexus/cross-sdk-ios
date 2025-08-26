//
//  SocketStatusView.swift
//  DappSample
//
//  Updated for new CrossSDKSwift API
//

import SwiftUI
import CrossSDKSwift

/// 연결 상태를 표시하는 컴포넌트 (새로운 CrossSDKSwift API 사용)
struct SocketStatusView: View {
    @ObservedObject private var sdk = CrossSDKSwift.shared

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // 연결 상태 인디케이터
                Circle()
                    .fill(connectionColor)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: connectionColor)

                Text("CrossSDK 상태")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(connectionColor)
            }

            // 추가 정보 표시
            if case .error(let error) = sdk.detailedConnectionState {
                Text("오류: \(error.localizedDescription)")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else if case .connecting = sdk.detailedConnectionState {
                Text("지갑 연결을 시도하고 있습니다")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if case .authenticating = sdk.detailedConnectionState {
                Text("지갑에서 연결 승인을 기다리고 있습니다")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(connectionColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var statusText: String {
        switch sdk.detailedConnectionState {
        case .idle:
            return "준비됨"
        case .disconnected:
            return "연결 안됨"
        case .connecting:
            return "연결 중"
        case .authenticating:
            return "인증 중"
        case .connected:
            return "연결됨"
        case .error:
            return "오류"
        }
    }

    private var connectionColor: Color {
        switch sdk.detailedConnectionState {
        case .idle:
            return .blue
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .authenticating:
            return .yellow
        case .connected:
            return .green
        case .error:
            return .red
        }
    }
}

#Preview {
    SocketStatusView()
        .padding()
}
