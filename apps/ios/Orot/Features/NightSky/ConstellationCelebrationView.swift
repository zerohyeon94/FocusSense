//
//  ConstellationCelebrationView.swift
//  Orot
//
//  별자리 완성 — 선이 1.5초 간격으로 하나씩 이어지고, 다 이어지면 이름과 뜻이 드러납니다.
//

import SwiftUI

struct ConstellationCelebrationView: View {
    let mansion: Mansion
    let sky: SkyProgress
    let onOpenNightSky: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var revealed = 0

    private let background = OrotColor.skyDeepNight
    private var isFullyDrawn: Bool { revealed >= mansion.segments.count }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            StarFieldView(field: .portrait, baseSize: CGSize(width: 390, height: 844), progress: 1, maxOpacity: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                constellation
                    .frame(height: 240)
                    .padding(.top, 70)

                VStack(spacing: 14) {
                    Text("\(KoreanOrdinal.word(sky.completionOrder(mansion))) 번째 별자리 완성")
                        .font(OrotFont.caption)
                        .tracking(0.7)
                        .foregroundStyle(OrotColor.accent)
                    Text(mansion.label)
                        .font(OrotFont.light(30))
                        .foregroundStyle(OrotColor.textPrimary)
                    Text(mansion.meaning)
                        .font(OrotFont.body)
                        .lineSpacing(6)
                        .foregroundStyle(Color(hex: 0x908D85))
                    Text(summaryText)
                        .font(OrotFont.caption)
                        .tracking(0.5)
                        .foregroundStyle(OrotColor.textCaption)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 50)
                .opacity(isFullyDrawn ? 1 : 0.15)
                .animation(.easeInOut(duration: 2), value: isFullyDrawn)

                Spacer()

                VStack(spacing: 4) {
                    Button("밤하늘에서 보기") {
                        dismiss()
                        onOpenNightSky()
                    }
                    .buttonStyle(OrotPrimaryButtonStyle())
                    ShareLink(item: shareImage, preview: SharePreview(mansion.label, image: shareImage)) {
                        Text("이미지로 공유하기")
                    }
                    .buttonStyle(OrotTextButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .presentationBackground(background)
        .task {
            // 선이 1.5초 간격으로 하나씩 이어집니다.
            while revealed < mansion.segments.count {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeInOut(duration: 1.4)) { revealed += 1 }
            }
        }
    }

    private var constellation: some View {
        ConstellationView(
            mansion: mansion,
            magnitudes: sky.magnitudes(mansion),
            starScale: 1.5,
            padding: 50,
            maxSpacing: 9,
            background: background,
            lineColor: Color(hex: 0x857B69),
            revealedSegments: revealed
        )
    }

    private var summaryText: String {
        guard let s = sky.summary(mansion) else { return "별 \(mansion.starCount)개" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        let minutes = Int(s.pureFocus / 60)
        let from = f.string(from: s.from), to = f.string(from: s.to)
        let period = from == to ? from : "\(from)부터 \(to)까지"
        return "별 \(mansion.starCount)개 · \(period) · 순수 집중 \(TodaySummary.duration(minutes: minutes))"
    }

    @MainActor
    private var shareImage: Image {
        let card = ZStack {
            background
            VStack(spacing: 18) {
                ConstellationView(mansion: mansion, magnitudes: sky.magnitudes(mansion), starScale: 1.5, padding: 40, maxSpacing: 9, background: background, lineColor: Color(hex: 0x857B69))
                    .frame(width: 342, height: 240)
                Text(mansion.label).font(OrotFont.light(26)).foregroundStyle(OrotColor.textPrimary)
                Text("오롯 · 집중한 만큼 별이 떠요").font(OrotFont.caption).foregroundStyle(OrotColor.textCaption)
            }
        }
        .frame(width: 390, height: 420)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) } ?? Image(systemName: "star")
    }
}
