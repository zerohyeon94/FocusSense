//
//  DashboardViewModel.swift
//  FocusSense
//
//  대시보드 홈 화면 ViewModel - GitHub 잔디 그래프 데이터 관리
//

import Foundation
import Combine

// MARK: - Dashboard ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedDay: DayActivity?
    @Published private(set) var weeklyGrid: [[DayActivity?]] = []
    @Published private(set) var monthLabels: [(String, Int)] = [] // (월 이름, 열 인덱스)

    // MARK: - Dependencies
    let sessionStore: StudySessionStore

    // MARK: - Configuration
    let weeksToShow = 16
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(sessionStore: StudySessionStore) {
        self.sessionStore = sessionStore
        setupBindings()
        computeContributionData()
    }

    // MARK: - Bindings
    private func setupBindings() {
        sessionStore.$sessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.computeContributionData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Compute Contribution Data
    func computeContributionData() {
        let today = calendar.startOfDay(for: Date())

        // 오늘의 요일 (1=일, 2=월, ..., 7=토)
        let todayWeekday = calendar.component(.weekday, from: today)

        // 총 표시할 열 수 (주 수 + 현재 주의 나머지)
        let totalColumns = weeksToShow + 1

        // 그래프 시작 날짜 계산: totalColumns 주 전의 일요일
        let daysBack = (totalColumns - 1) * 7 + (todayWeekday - 1)
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: today) else { return }

        // 세션을 날짜별로 그룹핑 (O(n))
        let sessionsByDay = Dictionary(grouping: sessionStore.sessions) { session in
            self.calendar.startOfDay(for: session.startTime)
        }

        // 그리드 초기화: 7행(일~토) x totalColumns열
        var grid: [[DayActivity?]] = Array(
            repeating: Array(repeating: nil, count: totalColumns),
            count: 7
        )

        // 월 라벨 계산용
        var labels: [(String, Int)] = []
        var lastMonth = -1

        for col in 0..<totalColumns {
            for row in 0..<7 {
                let dayOffset = col * 7 + row
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

                // 미래 날짜는 nil
                guard date <= today else { continue }

                let daySessions = sessionsByDay[calendar.startOfDay(for: date)] ?? []
                let totalDuration = daySessions.reduce(0) { $0 + $1.totalDuration }
                let avgFocusRate: Double = {
                    let withRecords = daySessions.filter { !$0.focusRecords.isEmpty }
                    guard !withRecords.isEmpty else { return 0 }
                    return withRecords.map { $0.focusRate }.reduce(0, +) / Double(withRecords.count)
                }()

                let activity = DayActivity(
                    date: date,
                    sessionCount: daySessions.count,
                    totalDuration: totalDuration,
                    averageFocusRate: avgFocusRate,
                    level: ActivityLevel.from(duration: totalDuration)
                )

                grid[row][col] = activity

                // 월 라벨: 첫 번째 행에서 월이 바뀌는 지점 감지
                if row == 0 {
                    let month = calendar.component(.month, from: date)
                    if month != lastMonth {
                        let monthFormatter = DateFormatter()
                        monthFormatter.locale = Locale(identifier: "ko_KR")
                        monthFormatter.dateFormat = "M월"
                        labels.append((monthFormatter.string(from: date), col))
                        lastMonth = month
                    }
                }
            }
        }

        weeklyGrid = grid
        monthLabels = labels
    }

    // MARK: - Summary Stats

    /// 오늘의 총 학습 시간
    var todayStudyTime: TimeInterval {
        sessionStore.todayTotalDuration
    }

    /// 이번 주 총 학습 시간
    var thisWeekStudyTime: TimeInterval {
        sessionStore.recentSessions(days: 7).reduce(0) { $0 + $1.totalDuration }
    }

    /// 연속 학습 일수 (스트릭)
    var currentStreak: Int {
        var streak = 0
        let today = calendar.startOfDay(for: Date())

        for i in 0... {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
            let daySessions = sessionStore.sessions(for: date)

            if daySessions.isEmpty {
                // 오늘 아직 학습 안 했으면 어제부터 카운트
                if i == 0 { continue }
                break
            }
            streak += 1
        }

        return streak
    }

    /// 이번 주 총 세션 수
    var thisWeekSessionCount: Int {
        sessionStore.recentSessions(days: 7).count
    }

    // MARK: - Cell Selection
    func selectDay(_ activity: DayActivity?) {
        if let activity = activity {
            // 같은 셀 다시 탭하면 해제
            if selectedDay?.date == activity.date {
                selectedDay = nil
            } else {
                selectedDay = activity
            }
        }
    }
}
