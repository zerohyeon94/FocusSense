//
//  SessionCompleteView.swift
//  Orot
//
//  세션 완료 — 시간 UI가 물러나고 새 별이 뜹니다.
//

import SwiftUI

struct SessionCompleteView: View {
    @ObservedObject var viewModel: TimerViewModel
    let landscape: Bool
    let onOpenNightSky: () -> Void

    @State private var revealed = false
    @State private var celebrating: Mansion?

    private var session: StudySession? { viewModel.completedSession }
    private var magnitude: Int { session?.starMagnitude ?? 3 }

    var body: some View {
        Group {
            if landscape { landscapeLayout } else { portraitLayout }
        }
        .onAppear {
            withAnimation(OrotMotion.star) { revealed = true }
            if let mansion = viewModel.sky.justCompletedMansion {
                Task {
                    try? await Task.sleep(for: .seconds(2.5))
                    celebrating = mansion
                }
            }
        }
        .sheet(item: $celebrating) { mansion in
            ConstellationCelebrationView(mansion: mansion, sky: viewModel.sky, onOpenNightSky: onOpenNightSky)
        }
    }

    // MARK: - Layouts
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            MoonCaption(prefix: "오늘은 ", size: 18)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 28)
                .padding(.top, 64)
            Spacer()
            newStar
            Spacer()
            headline
            stats.padding(.top, 28)
            actions.padding(.horizontal, 32).padding(.top, 36)
            Spacer()
            Spacer()
        }
    }

    private var landscapeLayout: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                headline
                stats.padding(.top, 20)
                actions.frame(width: 340).padding(.top, 28)
            }
            .padding(.leading, OrotSpace.screenInsetH)
            Spacer()
            newStar.padding(.trailing, 90)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Pieces
    private var newStar: some View {
        let size = landscape ? CGSize(width: 200, height: 125) : CGSize(width: 272, height: 170)
        return VStack(spacing: 8) {
            Text("새 별 · \(magnitude)등급")
                .font(OrotFont.caption)
                .tracking(0.5)
                .foregroundStyle(OrotColor.textSecondary)
            SessionConstellation(
                sky: viewModel.sky,
                mansion: viewModel.sky.lastPlaced?.mansion,
                next: .none,
                highlightLast: true,
                size: size,
                starScale: landscape ? 1.1 : 1.36,
                background: OrotColor.skyDeepNight,
                lineColor: Color(hex: 0x464A50),
                caption: viewModel.sky.completionCaption
            )
        }
        .opacity(revealed ? 1 : 0)
    }

    private var headline: some View {
        VStack(alignment: landscape ? .leading : .center, spacing: 6) {
            Text("세션 완료 · \(viewModel.subjectName)")
                .font(OrotFont.caption)
                .tracking(0.5)
                .foregroundStyle(OrotColor.textCaption)
            Text("새 별이 떴어요")
                .font(OrotFont.light(26))
                .foregroundStyle(OrotColor.textPrimary)
        }
    }

    private var stats: some View {
        let pure = session?.netFocusTime ?? viewModel.netFocusTime
        let total = session?.measuredDuration ?? viewModel.elapsedTime
        let ratio = Int(((session?.pureFocusRatio ?? viewModel.pureFocusRatio) * 100).rounded())
        return VStack(alignment: landscape ? .leading : .center, spacing: 10) {
            Text(TimerViewModel.clock(pure))
                .font(OrotFont.extraLight(72))
                .tracking(-0.7)
                .foregroundStyle(OrotColor.textPrimary)
            Text(viewModel.isDetectionEnabled
                 ? "순수 집중 · 전체 \(TimerViewModel.clock(total)) · \(ratio)%"
                 : "타이머로 잰 시간 · 기본 밝기 별")
                .font(OrotFont.caption)
                .tracking(0.5)
                .foregroundStyle(OrotColor.textSecondary)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button(viewModel.nextRestIsLong ? "\(Int(viewModel.longRestDuration / 60))분 쉬기" : "\(Int(viewModel.shortRestDuration / 60))분 쉬기") {
                viewModel.startRest()
            }
            .buttonStyle(OrotPrimaryButtonStyle(height: 48))
            Button("나의 밤하늘", action: onOpenNightSky)
                .buttonStyle(OrotSecondaryButtonStyle())
        }
    }
}
