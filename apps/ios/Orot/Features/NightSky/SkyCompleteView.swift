//
//  SkyCompleteView.swift
//  Orot
//
//  스물여덟 수를 모두 채운 뒤 한 번 보여 주는 안내 — 나만의 별자리(엔드게임) 예고
//

import SwiftUI

struct SkyCompleteView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ring
                .frame(width: 240, height: 240)
                .frame(maxWidth: .infinity)
                .padding(.top, 48)

            VStack(alignment: .leading, spacing: 14) {
                Text("스물여덟 수를 모두 채웠어요")
                    .font(OrotFont.caption)
                    .tracking(0.7)
                    .foregroundStyle(OrotColor.accent)
                Text("이제 나만의 별자리를\n그릴 수 있어요")
                    .font(OrotFont.light(28))
                    .lineSpacing(4)
                    .foregroundStyle(OrotColor.textPrimary)
                Text("앞으로 뜨는 별은 이름 없는 하늘에 놓여요. 마음에 드는 별을 이어 선을 긋고, 이름을 붙여 주세요.")
                    .font(OrotFont.body)
                    .lineSpacing(6)
                    .foregroundStyle(Color(hex: 0x908D85))
            }
            .padding(.horizontal, 8)
            .padding(.top, 36)

            Spacer()

            VStack(spacing: 10) {
                Button("밤하늘 보기") { dismiss() }
                    .buttonStyle(OrotPrimaryButtonStyle())
                Text("나만의 별자리 만들기는 다음 업데이트에서 열려요 · 28수 기록은 그대로 밤하늘에 남아요")
                    .font(OrotFont.caption)
                    .foregroundStyle(OrotColor.textCaption)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .presentationBackground(OrotColor.skyDeepNight)
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(Color(hex: 0x857B69), lineWidth: 1.5).frame(width: 184, height: 184)
            Circle().stroke(Color(hex: 0x23272B), style: StrokeStyle(lineWidth: 1, dash: [2, 5])).frame(width: 80, height: 80)
            ForEach(Mansion.all) { m in
                let a = (Double(m.index) * 360 / 28 - 90) * .pi / 180
                Text(m.hanja)
                    .font(OrotFont.regular(12))
                    .foregroundStyle(OrotColor.moonLit)
                    .position(x: 120 + 110 * cos(a), y: 120 + 110 * sin(a))
            }
            VStack(spacing: 2) {
                Text("28").font(OrotFont.extraLight(36)).foregroundStyle(OrotColor.textPrimary)
                Text("/ 28").font(OrotFont.regular(11)).foregroundStyle(OrotColor.textSecondary)
            }
        }
    }
}
