//
//  SkyTiles.swift
//  Orot
//
//  일 · 주 · 월 하늘 조각
//

import SwiftUI

// MARK: - Tile Stars
/// 조각 안에 그날 만든 별들을 흩어 놓습니다 (같은 날은 늘 같은 배치)
private struct TileStars: View {
    let magnitudes: [Int]
    let seed: Int64
    var scale: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            var r = SeededRandom(seed: seed)
            let points = magnitudes.map { _ in CGPoint(x: (0.18 + r.next() * 0.64) * geo.size.width, y: (0.14 + r.next() * 0.72) * geo.size.height) }
            ForEach(Array(magnitudes.enumerated()), id: \.offset) { i, m in
                StarDot(magnitude: m, scale: scale).position(points[i])
            }
        }
        .accessibilityHidden(true)
    }
}

private func daySeed(_ date: Date) -> Int64 {
    Int64(Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 1)
}

// MARK: - Day
struct DaySessionTiles: View {
    let sessions: [StudySession]

    var body: some View {
        if sessions.isEmpty {
            Text("오늘은 아직 세션이 없어요")
                .font(OrotFont.regular(13))
                .foregroundStyle(OrotColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 132)
                .overlay(RoundedRectangle(cornerRadius: OrotRadius.md).strokeBorder(OrotColor.hairline))
        } else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(sessions, id: \.id) { s in
                    ZStack(alignment: .bottomLeading) {
                        RecordFormat.sky(hours: s.pureFocusRatio * 3.2)
                        TileStars(magnitudes: [s.starMagnitude], seed: Int64(s.startTime.timeIntervalSince1970.truncatingRemainder(dividingBy: 9973)) + 1, scale: 1.4)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(RecordFormat.time(s.startTime)) · \(s.studyPlanTitle ?? "이름 없는 대상")")
                                .font(OrotFont.regular(13))
                                .foregroundStyle(OrotColor.textPrimary)
                            Text("\(RecordFormat.plannedMinutes(s))분 · \(Int((s.pureFocusRatio * 100).rounded()))% · \(s.starMagnitude)등급")
                                .font(OrotFont.regular(11))
                                .tracking(0.4)
                                .foregroundStyle(OrotColor.textSecondary)
                        }
                        .padding(12)
                    }
                    .frame(height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: OrotRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: OrotRadius.md).strokeBorder(OrotColor.hairline))
                }
            }
        }
    }
}

// MARK: - Week
struct WeekSkyTiles: View {
    let sessions: [StudySession]

    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days = (0..<7).map { cal.date(byAdding: .day, value: $0 - 6, to: today)! }
        HStack(spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                let list = sessions.filter { cal.isDate($0.startTime, inSameDayAs: day) }
                let hours = list.reduce(0) { $0 + $1.netFocusTime } / 3600
                let isToday = i == 6
                VStack(spacing: 6) {
                    Text(String(format: "%.1f", hours))
                        .font(OrotFont.regular(11))
                        .monospacedDigit()
                        .foregroundStyle(OrotColor.textCaption)
                    ZStack {
                        RecordFormat.sky(hours: hours)
                        TileStars(magnitudes: list.map(\.starMagnitude), seed: daySeed(day))
                    }
                    .frame(height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isToday ? OrotColor.accent.opacity(0.6) : OrotColor.hairline))
                    Text(isToday ? "오늘" : day.formatted(.dateTime.weekday(.narrow).locale(Locale(identifier: "ko_KR"))))
                        .font(OrotFont.caption)
                        .foregroundStyle(isToday ? OrotColor.textPrimary : OrotColor.textCaption)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(RecordFormat.monthDay(day)), 별 \(list.count)개, 순수 집중 \(RecordFormat.hoursMinutes(hours * 3600))")
            }
        }
    }
}

// MARK: - Month
struct MonthSkyTiles: View {
    let sessions: [StudySession]

    var body: some View {
        let cal = Calendar.current
        let now = Date()
        let first = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let leading = cal.component(.weekday, from: first) - 1
        let count = cal.range(of: .day, in: .month, for: now)!.count
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) {
                Text($0).font(OrotFont.regular(11)).foregroundStyle(OrotColor.textCaption)
            }
            ForEach(0..<leading, id: \.self) { _ in Color.clear.aspectRatio(1, contentMode: .fit) }
            ForEach(1...count, id: \.self) { d in
                let day = cal.date(byAdding: .day, value: d - 1, to: first)!
                let list = sessions.filter { cal.isDate($0.startTime, inSameDayAs: day) }
                let hours = list.reduce(0) { $0 + $1.netFocusTime } / 3600
                ZStack(alignment: .topLeading) {
                    (list.isEmpty ? Color.clear : RecordFormat.sky(hours: hours))
                    TileStars(magnitudes: list.map(\.starMagnitude), seed: daySeed(day), scale: 0.6)
                    Text("\(d)").font(OrotFont.regular(9)).foregroundStyle(OrotColor.textCaption).padding(.leading, 5).padding(.top, 3)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(list.isEmpty ? Color(hex: 0x23272B) : OrotColor.hairline))
            }
        }
    }
}
