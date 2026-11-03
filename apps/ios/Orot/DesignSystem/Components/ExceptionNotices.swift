//
//  ExceptionNotices.swift
//  Orot
//
//  예외 상태 안내 — 처벌이 아니라 안내. 빨간색 대신 달빛 청회색 점 하나로 표시하고,
//  "무슨 일이 생겼는지" 한 문장, "무엇을 하면 되는지" 한 문장으로 씁니다.
//

import SwiftUI

private struct InfoDot: View {
    var body: some View {
        Circle().fill(OrotColor.stateOvertime).frame(width: 6, height: 6)
    }
}

// MARK: - Banner (발열 등)
struct ExceptionBanner: View {
    let message: String
    let detail: String
    /// 가로 화면에서는 한 줄 알약 모양
    var compact = false

    var body: some View {
        Group {
            if compact {
                HStack(spacing: 10) {
                    InfoDot()
                    Text(message).foregroundStyle(OrotColor.textPrimary)
                    Text(detail).foregroundStyle(Color(hex: 0x7E7B74))
                }
                .font(OrotFont.regular(13))
                .lineLimit(1)
                .padding(.leading, 12).padding(.trailing, 14)
                .frame(height: 34)
                .background(Capsule().fill(OrotColor.surfaceRaised.opacity(0.92)))
                .overlay(Capsule().strokeBorder(OrotColor.hairline))
            } else {
                HStack(alignment: .top, spacing: 10) {
                    InfoDot().padding(.top, 7)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message).font(OrotFont.regular(13)).foregroundStyle(OrotColor.textPrimary)
                        Text(detail).font(OrotFont.caption).foregroundStyle(Color(hex: 0x7E7B74))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(OrotColor.surfaceRaised.opacity(0.96)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(OrotColor.hairline))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Card (카메라를 쓸 수 없음 · 권한 꺼짐)
struct ExceptionCard: View {
    let message: String
    let detail: String
    let primary: String
    let secondary: String
    let onPrimary: () -> Void
    let onSecondary: () -> Void
    var compact = false

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                InfoDot().padding(.top, 8)
                VStack(alignment: .leading, spacing: 4) {
                    Text(message).font(OrotFont.regular(14)).lineSpacing(3).foregroundStyle(OrotColor.textPrimary)
                    Text(detail).font(OrotFont.regular(13)).lineSpacing(3).foregroundStyle(OrotColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            VStack(spacing: 2) {
                Button(primary, action: onPrimary)
                    .buttonStyle(OrotPrimaryButtonStyle(height: compact ? 44 : 48))
                Button(secondary, action: onSecondary)
                    .buttonStyle(OrotTextButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, compact ? 6 : 10)
        .background(RoundedRectangle(cornerRadius: OrotRadius.lg).fill(OrotColor.surfaceRaised.opacity(0.97)))
        .overlay(RoundedRectangle(cornerRadius: OrotRadius.lg).strokeBorder(OrotColor.hairline))
        .shadow(color: .black.opacity(0.55), radius: 24, y: 16)
    }
}

// MARK: - Notification Off (6-4)
struct NotificationOffNotice: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                InfoDot().padding(.top, 7)
                VStack(alignment: .leading, spacing: 2) {
                    Text("알림이 꺼져 있어서 세션이 끝난 걸 놓칠 수 있어요.").font(OrotFont.regular(13)).foregroundStyle(OrotColor.textPrimary)
                    Text("필요하면 설정에서 알림을 켜 주세요.").font(OrotFont.caption).foregroundStyle(Color(hex: 0x7E7B74))
                }
                Spacer(minLength: 0)
            }
            .padding(.trailing, 8)
            HStack(spacing: 2) {
                Spacer()
                Button("괜찮아요", action: onDismiss)
                    .font(OrotFont.regular(13)).foregroundStyle(Color(hex: 0x7E7B74))
                    .frame(height: 36).padding(.horizontal, 12)
                Button("알림 켜기") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { UIApplication.shared.open(url) }
                }
                .font(OrotFont.regular(13)).foregroundStyle(OrotColor.accent)
                .frame(height: 36).padding(.horizontal, 12)
            }
        }
        .padding(.leading, 16).padding(.trailing, 8).padding(.top, 14).padding(.bottom, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(OrotColor.skyNight.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(OrotColor.hairline))
    }
}
