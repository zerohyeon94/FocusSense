//
//  SessionRestView.swift
//  Orot
//
//  휴식 — 초저녁 하늘로 한 단계 밝아지고 도시 불빛이 다시 켜집니다.
//

import SwiftUI

struct SessionRestView: View {
    @ObservedObject var viewModel: TimerViewModel
    let landscape: Bool

    private let clockColor = Color(hex: 0xC0B7A6)

    var body: some View {
        if landscape { landscapeLayout } else { portraitLayout }
    }

    // MARK: - Layouts
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            MoonCaption(size: 18)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 28)
                .padding(.top, 64)
            constellation(size: CGSize(width: 272, height: 170), scale: 1.36, alignment: .center)
                .padding(.top, 50)
            Spacer()
            VStack(spacing: 14) {
                SessionBadge(state: .rest)
                SessionClock(text: viewModel.restClockText, size: 116, color: clockColor)
                message(alignment: .center, caption: "창밖 진짜 하늘도 한번 올려다보세요 · \(nextLabel)")
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            Spacer()
            actions.padding(.bottom, 36)
        }
    }

    private var landscapeLayout: some View {
        ZStack(alignment: .topLeading) {
            MoonCaption()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 56)
                .padding(.top, 32)

            constellation(size: CGSize(width: 160, height: 100), scale: 1, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 110)
                .padding(.top, 62)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    SessionBadge(state: .rest)
                    Text(nextLabel)
                        .font(OrotFont.label)
                        .foregroundStyle(OrotColor.textSecondary)
                }
                SessionClock(text: viewModel.restClockText, size: 172, color: clockColor)
                    .padding(.leading, -8)
                message(alignment: .leading, caption: "창밖 진짜 하늘도 한번 올려다보세요")
                    .padding(.top, 6)
            }
            .padding(.leading, OrotSpace.screenInsetH)
            .padding(.top, 66)

            actions
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 60)
                .padding(.bottom, 70)
        }
    }

    // MARK: - Pieces
    private func constellation(size: CGSize, scale: CGFloat, alignment: Alignment) -> some View {
        let sky = viewModel.sky
        let caption = sky.currentMansion.map { "다음 세션에서 채울 별 · \($0.label)의 \(sky.nextStarOrdinal)" } ?? sky.progressCaption()
        return SessionConstellation(
            sky: sky,
            next: .waiting,
            size: size,
            starScale: scale,
            background: OrotColor.skyEvening,
            caption: caption,
            captionAlignment: alignment
        )
    }

    private var nextLabel: String { "다음은 \(viewModel.subjectName) \(viewModel.targetMinutes)분" }

    private func message(alignment: HorizontalAlignment, caption: String) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text("눈을 잠시 멀리 두세요")
                .font(OrotFont.body)
                .foregroundStyle(OrotColor.textPrimary)
            Text(caption)
                .font(OrotFont.caption)
                .tracking(0.5)
                .foregroundStyle(Color(hex: 0x6E6B64))
        }
        .multilineTextAlignment(alignment == .center ? .center : .leading)
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button("오늘은 여기까지") { viewModel.closeSession() }
                .font(OrotFont.regular(13))
                .foregroundStyle(OrotColor.textCaption)
                .frame(height: 44)
                .padding(.horizontal, 12)
            Button("바로 다음 세션 시작") { viewModel.startNextFocus() }
                .font(OrotFont.regular(13))
                .foregroundStyle(Color(hex: 0x95928A))
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(Capsule().fill(OrotColor.skyEvening.opacity(0.75)))
                .overlay(Capsule().strokeBorder(Color(hex: 0x353B43)))
        }
        .buttonStyle(.plain)
    }
}
