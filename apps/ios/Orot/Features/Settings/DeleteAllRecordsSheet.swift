//
//  DeleteAllRecordsSheet.swift
//  Orot
//
//  모든 기록 삭제 확인 (5-4) — 빨간색 대신 안전한 선택을 강조하고, 체크해야 삭제가 켜져요.
//

import SwiftUI

struct DeleteAllRecordsSheet: View {
    @ObservedObject var sessionStore: StudySessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var acknowledged = false

    var body: some View {
        let sky = sessionStore.sky
        let pure = sessionStore.sessions.reduce(0) { $0 + $1.netFocusTime }
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("모든 기록을 지울까요?").font(OrotFont.light(20)).foregroundStyle(OrotColor.textPrimary)
                Text("한 번 지우면 되돌릴 수 없어요.").font(OrotFont.regular(14)).foregroundStyle(Color(hex: 0x908D85))
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("함께 사라지는 것").font(OrotFont.caption).tracking(0.5).foregroundStyle(OrotColor.textCaption)
                    .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 4)
                row("세션 기록", "\(sessionStore.sessions.count)개")
                row("만든 별", "\(sky.records.count)개")
                row("별자리 진행도", "\(sky.completedCount) / 28 · \(sky.progressCaption())")
                row("순수 집중 시간", RecordFormat.hoursMinutes(pure))
                Text("지우기 전에 설정 › 기록 내보내기로 보관할 수 있어요.").font(OrotFont.caption).foregroundStyle(OrotColor.textCaption)
                    .padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 12)
            }
            .overlay(RoundedRectangle(cornerRadius: OrotRadius.md).strokeBorder(OrotColor.hairline))

            Button { acknowledged.toggle() } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(acknowledged ? OrotColor.accent : .clear)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(acknowledged ? OrotColor.accent : OrotColor.textCaption, lineWidth: 1.5))
                        .overlay(Text(acknowledged ? "✓" : "").font(OrotFont.regular(13)).foregroundStyle(OrotColor.skyNight))
                        .frame(width: 22, height: 22)
                    Text("되돌릴 수 없다는 걸 이해했어요").font(OrotFont.regular(14)).foregroundStyle(OrotColor.textPrimary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(OrotMotion.tap, value: acknowledged)
            .accessibilityAddTraits(acknowledged ? .isSelected : [])

            VStack(spacing: 8) {
                Button("기록 남겨두기") { dismiss() }
                    .buttonStyle(OrotPrimaryButtonStyle(height: 50))
                Button {
                    sessionStore.deleteAllSessions()
                    dismiss()
                } label: {
                    Text("모든 기록 지우기")
                        .font(OrotFont.regular(15))
                        .foregroundStyle(acknowledged ? OrotColor.textPrimary : Color(hex: 0x4A4E54))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(Capsule().strokeBorder(acknowledged ? OrotColor.textSecondary : Color(hex: 0x23272B)))
                }
                .buttonStyle(.plain)
                .disabled(!acknowledged)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 18)
        .presentationDetents([.height(560)])
        .presentationBackground(OrotColor.surfaceRaised)
        .presentationDragIndicator(.visible)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(OrotColor.textPrimary)
            Spacer()
            Text(value).monospacedDigit().foregroundStyle(OrotColor.textSecondary).lineLimit(1)
        }
        .font(OrotFont.regular(14))
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}
