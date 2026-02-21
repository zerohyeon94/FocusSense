//
//  DashboardViewModel.swift
//  FocusSense
//
//  대시보드 홈 화면 ViewModel (잔디 그래프 데이터 계산)
//

import Foundation
import Combine

// MARK: - Dashboard ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var weeklyGrid: [[DayActivity?]] = []
    @Published var selectedDay: DayActivity?
    @Published var todayStudyTime: TimeInterval = 0
    @Published var thisWeekStudyTime: TimeInterval = 0
    @Published var currentStreak: Int = 0

    // MARK: - Dependencies
    private let sessionStore: StudySessionStore
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private let weeksToShow = 16

    // MARK: - Initialization
    init(sessionStore: StudySessionStore) {
        self.sessionStore = sessionStore
        setupBindings()
    }

    // MARK: - Setup Bindings
    private func setupBindings() {
        sessionStore.$sessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.computeAll()
            }
            .store(in: &cancellables)
    }

    // MARK: - Compute All
    func computeAll() {
        computeContributionData()
        computeStats()
    }

    // MARK: - Contribution Graph Data
    private func computeContributionData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeksToShow * 7 + 7 // 여유 포함

        guard let startDate = calendar.date(byAdding: .day, value: -totalDays, to: today) else { return }

        // 세션을 날짜별로 그룹핑
        let recentSessions = sessionStore.sessions.filter { $0.startTime >= startDate }
        let grouped = Dictionary(grouping: recentSessions) { session -> Date in
            calendar.startOfDay(for: session.startTime)
        }

        // 날짜별 활동 데이터 생성
        var activities: [Date: DayActivity] = [:]
        for (date, sessions) in grouped {
            let totalDuration = sessions.reduce(0) { $0 + $1.totalDuration }
            let avgFocusRate: Double = sessions.isEmpty ? 0 :
                sessions.map { $0.focusRate }.reduce(0, +) / Double(sessions.count)

            activities[date] = DayActivity(
                date: date,
                sessionCount: sessions.count,
                totalDuration: totalDuration,
                averageFocusRate: avgFocusRate,
                level: ActivityLevel.from(duration: totalDuration)
            )
        }

        // 그리드 생성: 7행(일~토) x (weeksToShow+1)열
        let todayWeekday = calendar.component(.weekday, from: today) // 1=일, 7=토

        // 그리드 시작점: weeksToShow주 전의 일요일
        let todayDayOffset = todayWeekday - 1 // 일요일부터 오늘까지 오프셋
        let totalColumns = weeksToShow + 1
        guard let gridStartDate = calendar.date(byAdding: .day, value: -(weeksToShow * 7 + todayDayOffset), to: today) else { return }

        var grid: [[DayActivity?]] = Array(repeating: Array(repeating: nil, count: totalColumns), count: 7)

        for col in 0..<totalColumns {
            for row in 0..<7 {
                let dayOffset = col * 7 + row
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: gridStartDate) else { continue }

                // 미래 날짜 제외
                if date > today { continue }

                if let activity = activities[date] {
                    grid[row][col] = activity
                } else {
                    grid[row][col] = DayActivity(
                        date: date,
                        sessionCount: 0,
                        totalDuration: 0,
                        averageFocusRate: 0,
                        level: .none
                    )
                }
            }
        }

        weeklyGrid = grid
    }

    // MARK: - Stats
    private func computeStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 오늘 학습 시간
        todayStudyTime = sessionStore.todaySessions.reduce(0) { $0 + $1.totalDuration }

        // 이번 주 학습 시간
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        let weekSessions = sessionStore.sessions.filter {
            calendar.startOfDay(for: $0.startTime) >= weekStart
        }
        thisWeekStudyTime = weekSessions.reduce(0) { $0 + $1.totalDuration }

        // 연속 학습일
        var streak = 0
        var checkDate = today
        while true {
            let daySessions = sessionStore.sessions.filter {
                calendar.startOfDay(for: $0.startTime) == checkDate
            }
            if daySessions.isEmpty {
                // 오늘은 아직 학습 안 했을 수 있으므로 한 번 더 체크
                if checkDate == today {
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                    continue
                }
                break
            }
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        currentStreak = streak
    }

    // MARK: - Month Labels
    func monthLabel(for columnIndex: Int) -> String? {
        guard columnIndex < (weeklyGrid.first?.count ?? 0) else { return nil }

        // 첫 번째 행(일요일)에서 날짜 가져오기
        guard let activity = weeklyGrid[0][columnIndex] else { return nil }

        let calendar = Calendar.current
        let day = calendar.component(.day, from: activity.date)

        // 해당 주의 1일~7일 사이면 월 표시
        if day <= 7 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월"
            return formatter.string(from: activity.date)
        }
        return nil
    }
}
