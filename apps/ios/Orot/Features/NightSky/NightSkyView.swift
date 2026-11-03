//
//  NightSkyView.swift
//  Orot
//
//  밤하늘 탭 — 28수 성도(3-1)에서 수를 누르면 별자리 상세(3-2)로 갑니다.
//  스물여덟 수를 모두 채우면 엔드게임 안내(3-4)를 한 번 보여 줍니다.
//

import SwiftUI

struct NightSkyView: View {
    @ObservedObject var sessionStore: StudySessionStore

    @State private var path: [Mansion] = []
    @AppStorage("sky.endgameSeen") private var endgameSeen = false
    @State private var showsEndgame = false

    private let background = Color(hex: 0x0E1013)

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                background.ignoresSafeArea()

                SkyMapView(sky: sessionStore.sky) { path.append($0) }
                    .padding(.top, 104)

                header
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .background(background)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Mansion.self) { mansion in
                MansionDetailView(mansion: mansion, sky: sessionStore.sky)
            }
        }
        .onAppear {
            if sessionStore.sky.isAllComplete && !endgameSeen { showsEndgame = true }
        }
        .sheet(isPresented: $showsEndgame, onDismiss: { endgameSeen = true }) {
            SkyCompleteView()
        }
    }

    private var header: some View {
        let sky = sessionStore.sky
        let moon = MoonPhase()
        return VStack(alignment: .leading, spacing: 14) {
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
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(Text("\(sky.completedCount)").font(OrotFont.extraLight(36)))\(Text(" / 28").font(OrotFont.extraLight(18)).foregroundStyle(OrotColor.textCaption))")
                    .foregroundStyle(OrotColor.textPrimary)
                if let current = sky.currentMansion {
                    Text("별자리 완성 · 지금 \(Text(sky.progressCaption(current)).foregroundStyle(OrotColor.accent))")
                        .font(OrotFont.caption)
                        .tracking(0.5)
                        .foregroundStyle(OrotColor.textSecondary)
                } else {
                    Text("스물여덟 수를 모두 채웠어요")
                        .font(OrotFont.caption)
                        .foregroundStyle(OrotColor.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
