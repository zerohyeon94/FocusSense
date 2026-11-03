//
//  NightSkyView.swift
//  Orot
//
//  밤하늘 탭 — 28수 성도는 2단계에서 채웁니다. 지금은 머리말과 오늘의 달만 보여 줍니다.
//

import SwiftUI

struct NightSkyView: View {
    var body: some View {
        let moon = MoonPhase()
        ZStack(alignment: .top) {
            Color(hex: 0x0E1013).ignoresSafeArea()
            StarFieldView(field: .portrait, baseSize: CGSize(width: 390, height: 844), progress: 1, maxOpacity: 0.3)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("밤하늘")
                        .font(OrotFont.title)
                        .foregroundStyle(OrotColor.textPrimary)
                    Spacer()
                    HStack(spacing: 8) {
                        Text("\(moon.name) · 월령 \(moon.age)일")
                            .font(OrotFont.caption)
                            .foregroundStyle(OrotColor.textCaption)
                        MoonPhaseIcon(phase: moon, size: 20)
                    }
                }
                .padding(.top, 12)

                Spacer()
                Text("스물여덟 수의 하늘을 준비하고 있어요")
                    .font(OrotFont.body)
                    .foregroundStyle(OrotColor.textSecondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
