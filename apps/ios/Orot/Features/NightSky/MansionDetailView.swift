//
//  MansionDetailView.swift
//  Orot
//
//  별자리 상세 — 수의 이름과 뜻, 별을 누르면 그 별을 만든 세션 기록이 나옵니다.
//

import SwiftUI

struct MansionDetailView: View {
    let mansion: Mansion
    let sky: SkyProgress

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStar = 0

    private let background = Color(hex: 0x0E1013)
    private var state: MansionState { sky.state(mansion) }
    private var filled: Int { sky.filledCount(mansion) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button { dismiss() } label: {
                    Text("‹ 밤하늘")
                        .font(OrotFont.regular(15))
                        .foregroundStyle(OrotColor.textSecondary)
                        .frame(height: 44)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
                .padding(.leading, -10)

                header.padding(.top, 12)

                Text(mansion.meaning)
                    .font(OrotFont.body)
                    .lineSpacing(5)
                    .foregroundStyle(Color(hex: 0x908D85))
                    .padding(.top, 24)

                ConstellationView(
                    mansion: mansion,
                    magnitudes: sky.magnitudes(mansion),
                    next: state == .current ? .forming(0.3) : .none,
                    starScale: 1.4,
                    padding: 40,
                    maxSpacing: 9,
                    background: background,
                    lineColor: state == .current ? Color(hex: 0x7C705D) : Color(hex: 0x6A655B),
                    selectedStar: selectedStar,
                    onTapStar: { selectedStar = $0 }
                )
                .frame(height: 240)
                .overlay(RoundedRectangle(cornerRadius: OrotRadius.lg).strokeBorder(Color(hex: 0x23272B)))
                .padding(.top, 24)

                StarInfoCard(mansion: mansion, sky: sky, star: min(selectedStar, mansion.starCount - 1))
                    .padding(.top, 20)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { selectedStar = state == .current ? filled : 0 }
    }

    private var header: some View {
        HStack(spacing: 18) {
            Text(mansion.hanja)
                .font(OrotFont.light(64))
                .foregroundStyle(OrotColor.textPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(mansion.korean)수 \(Text("\(mansion.hanja)宿").font(OrotFont.regular(15)).foregroundStyle(OrotColor.textCaption))")
                    .font(OrotFont.title)
                    .foregroundStyle(OrotColor.textPrimary)
                Text("\(mansion.direction.name) · \(KoreanOrdinal.word(mansion.orderInDirection)) 번째 수 · 별 \(mansion.starCount)개")
                    .font(OrotFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(OrotColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
            Text(stateLabel)
                .font(OrotFont.caption)
                .foregroundStyle(stateColor)
                .padding(.horizontal, 11)
                .frame(height: 26)
                .overlay(Capsule().strokeBorder(OrotColor.hairline))
                .fixedSize()
        }
    }

    private var stateLabel: String {
        switch state {
        case .done: return "완성 · \(mansion.starCount) / \(mansion.starCount)"
        case .current: return "진행 중 · \(filled) / \(mansion.starCount)"
        case .todo: return "아직"
        }
    }

    private var stateColor: Color {
        switch state {
        case .done: return OrotColor.moonLit
        case .current: return OrotColor.accent
        case .todo: return OrotColor.textCaption
        }
    }
}

// MARK: - Star Info Card
private struct StarInfoCard: View {
    let mansion: Mansion
    let sky: SkyProgress
    let star: Int

    private static let dateFormat: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f
    }()

    var body: some View {
        let record = sky.record(mansion, star: star)
        let isForming = sky.state(mansion) == .current && star == sky.filledCount(mansion)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    if let record {
                        StarDot(magnitude: record.magnitude, scale: 1.2)
                    } else {
                        Circle().strokeBorder(OrotColor.textCaption).frame(width: 7, height: 7)
                    }
                    Text(record.map { "\($0.magnitude)등급 별" } ?? (isForming ? "지금 떠오르는 별" : "빈 자리"))
                        .font(OrotFont.body)
                        .foregroundStyle(OrotColor.textPrimary)
                }
                Spacer()
                Text("\(star + 1) / \(mansion.starCount)번째 별")
                    .font(OrotFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(OrotColor.textCaption)
            }

            if let record {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    row("만든 날", Self.dateFormat.string(from: record.date))
                    row("집중 대상", record.subject)
                    row("순수 집중", "\(Int((record.focusRatio * 100).rounded()))% · \(Int(record.pureFocus / 60))분 / \(Int(record.total / 60))분")
                }
                .font(OrotFont.regular(13))
            } else {
                Text(isForming ? "다음 세션을 마치면 이 자리에 별이 떠요. 집중 비율이 높을수록 밝아져요." : "아직 비어 있어요. 앞의 별들이 채워지면 차례로 이어져요.")
                    .font(OrotFont.regular(13))
                    .lineSpacing(4)
                    .foregroundStyle(OrotColor.textSecondary)
            }
        }
        .padding(18)
        .overlay(RoundedRectangle(cornerRadius: OrotRadius.md).strokeBorder(OrotColor.hairline))
    }

    private func row(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(OrotColor.textCaption)
            Text(value).foregroundStyle(OrotColor.textPrimary).monospacedDigit()
        }
    }
}
