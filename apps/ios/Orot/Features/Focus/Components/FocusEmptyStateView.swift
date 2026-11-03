//
//  FocusEmptyStateView.swift
//  Orot
//
//  첫 세션 전 빈 상태 — 불빛이 가득한 초저녁 도시
//

import SwiftUI

struct FocusEmptyStateView: View {
    let onStart: () -> Void
    let onCustomize: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            OrotColor.skyDusk.ignoresSafeArea()
            CityGlow(height: 420, opacity: 0.75, color: Color(hex: 0x4A3720))
            SkylineView(style: .tall, progress: -1, buildingColor: Color(hex: 0x1B2026), windowIntensity: 1)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onSettings) { SettingsGlyph(background: OrotColor.skyDusk) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("설정")
                }
                .padding(.trailing, 14)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 20) {
                    Text("아직 하늘에 별이 없어요")
                        .font(OrotFont.caption)
                        .tracking(0.5)
                        .foregroundStyle(Color(hex: 0x76736C))
                    Text("첫 별을\n띄워 보세요")
                        .font(OrotFont.extraLight(54))
                        .lineSpacing(-12)
                        .tracking(-1)
                        .foregroundStyle(OrotColor.textPrimary)
                    Text("25분 동안 오롯이 집중하면 불빛이 하나씩 꺼지고, 이 하늘에 첫 별이 떠요.")
                        .font(OrotFont.body)
                        .lineSpacing(5)
                        .foregroundStyle(Color(hex: 0x908D85))
                }
                .padding(.horizontal, 28)
                .padding(.top, 52)

                Spacer()

                VStack(spacing: 6) {
                    Button("25분으로 시작하기", action: onStart)
                        .buttonStyle(OrotPrimaryButtonStyle())
                    Button("시간과 대상 바꾸기", action: onCustomize)
                        .buttonStyle(OrotTextButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 37)
            }
        }
    }
}
