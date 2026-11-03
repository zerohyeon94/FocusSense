//
//  SkyProgress.swift
//  Orot
//
//  저장된 세션을 시작 시각 순서로 28수 빈자리에 차례로 놓습니다. (세션 하나 = 별 하나)
//

import Foundation

// MARK: - Star Record
/// 하늘에 놓인 별 하나의 기록
struct StarRecord: Equatable {
    let sessionID: UUID
    let magnitude: Int
    let date: Date
    let subject: String
    let focusRatio: Double
    let pureFocus: TimeInterval
    let total: TimeInterval

    init(session: StudySession) {
        sessionID = session.id
        magnitude = session.starMagnitude
        date = session.startTime
        subject = session.studyPlanTitle ?? "이름 없는 대상"
        focusRatio = session.pureFocusRatio
        pureFocus = session.netFocusTime
        total = session.plannedDuration > 0 ? session.plannedDuration : session.measuredDuration
    }
}

// MARK: - Mansion State
enum MansionState {
    case done, current, todo
}

// MARK: - Sky Progress
struct SkyProgress {
    /// 시작 시각 순서로 정렬한 별 기록
    let records: [StarRecord]

    static let empty = SkyProgress(records: [])

    init(records: [StarRecord]) {
        self.records = records
    }

    init(sessions: [StudySession]) {
        records = sessions
            .filter { $0.endTime != nil }
            .sorted { $0.startTime < $1.startTime }
            .prefix(Mansion.totalStars)
            .map(StarRecord.init(session:))
    }

    /// 이 수의 첫 별 앞에 놓인 별 수
    private func offset(of mansion: Mansion) -> Int {
        Mansion.all.prefix(mansion.index).reduce(0) { $0 + $1.starCount }
    }

    func filledCount(_ mansion: Mansion) -> Int {
        min(mansion.starCount, max(0, records.count - offset(of: mansion)))
    }

    func record(_ mansion: Mansion, star: Int) -> StarRecord? {
        guard star < filledCount(mansion) else { return nil }
        return records[offset(of: mansion) + star]
    }

    func magnitudes(_ mansion: Mansion) -> [Int] {
        (0..<filledCount(mansion)).compactMap { record(mansion, star: $0)?.magnitude }
    }

    func state(_ mansion: Mansion) -> MansionState {
        let filled = filledCount(mansion)
        if filled == mansion.starCount { return .done }
        return mansion == currentMansion ? .current : .todo
    }

    /// 지금 채우는 중인 수 (모두 채웠으면 nil)
    var currentMansion: Mansion? {
        Mansion.all.first { filledCount($0) < $0.starCount }
    }

    var completedCount: Int {
        Mansion.all.filter { filledCount($0) == $0.starCount }.count
    }

    var isAllComplete: Bool { records.count >= Mansion.totalStars }

    /// 이 세션의 별이 놓인 수와 자리
    func place(of sessionID: UUID) -> (mansion: Mansion, star: Int)? {
        guard var index = records.firstIndex(where: { $0.sessionID == sessionID }) else { return nil }
        for m in Mansion.all {
            if index < m.starCount { return (m, index) }
            index -= m.starCount
        }
        return nil
    }

    /// 가장 최근 별이 들어간 수와 그 별의 자리
    var lastPlaced: (mansion: Mansion, star: Int)? {
        guard !records.isEmpty else { return nil }
        var remaining = records.count - 1
        for m in Mansion.all {
            if remaining < m.starCount { return (m, remaining) }
            remaining -= m.starCount
        }
        return nil
    }

    /// 가장 최근 별이 별자리를 완성했으면 그 수
    var justCompletedMansion: Mansion? {
        guard let last = lastPlaced, last.star == last.mansion.starCount - 1 else { return nil }
        return last.mansion
    }

    /// 수가 몇 번째로 완성됐는지 (완성 축하 문구용)
    func completionOrder(_ mansion: Mansion) -> Int {
        Mansion.all.prefix(mansion.index + 1).filter { filledCount($0) == $0.starCount }.count
    }

    /// 완성된 수의 기간과 순수 집중 합계
    func summary(_ mansion: Mansion) -> (from: Date, to: Date, pureFocus: TimeInterval)? {
        let list = (0..<filledCount(mansion)).compactMap { record(mansion, star: $0) }
        guard let first = list.first, let last = list.last else { return nil }
        return (first.date, last.date, list.reduce(0) { $0 + $1.pureFocus })
    }
}
