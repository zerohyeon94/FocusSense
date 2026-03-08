//
//  DashboardViewModel.swift
//  FocusSense
//
//  대시보드 홈 화면 ViewModel (잔디 그래프 데이터 계산)
//

// ============================================================================
// 📚 [파일 개요] DashboardViewModel - 대시보드 화면의 ViewModel
// ============================================================================
//
// 📚 아키텍처 다이어그램:
//
//   DashboardView (SwiftUI)
//       │
//       ▼
//   DashboardViewModel (@MainActor, ObservableObject)
//       │
//       └── StudySessionStore ──($sessions Publisher)──▶ Combine 구독
//                                                         │
//                                                         ▼
//                                                    computeAll()
//                                                    ├── computeContributionData() → weeklyGrid (잔디 그래프)
//                                                    └── computeStats()            → 통계 (오늘/이번주/연속일)
//
// 📚 [이 ViewModel의 핵심 개념들]
//    1. Combine 반응형 프로그래밍: 세션 데이터가 변경되면 자동으로 통계를 재계산
//    2. Calendar API: 날짜 계산의 다양한 활용법
//    3. 고차함수: Dictionary(grouping:), reduce, map, filter
//    4. 2차원 배열: GitHub 스타일 잔디(Contribution) 그래프 데이터 구조
//    5. 연속 학습일(Streak) 알고리즘: while 루프를 활용한 연속일 계산
//
// ============================================================================

import Foundation
import Combine

// MARK: - Dashboard ViewModel

// 📚 [@MainActor + ObservableObject]
//    TimerViewModel과 동일한 패턴입니다.
//    @MainActor: 모든 프로퍼티/메서드가 메인 스레드에서 실행 보장
//    ObservableObject: @Published 프로퍼티 변경 시 SwiftUI View 자동 갱신
//
//    DashboardView에서는 이 ViewModel을 @StateObject 또는 @ObservedObject로
//    관찰하면, weeklyGrid, todayStudyTime 등이 바뀔 때마다 화면이 자동으로 갱신됩니다.
@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    // 📚 [2차원 배열 타입: [[DayActivity?]]]
    //    weeklyGrid는 "GitHub 잔디 그래프"와 같은 격자 데이터입니다.
    //    구조: grid[row][col] = DayActivity? (7행 x N열)
    //    - row (0~6): 요일 (일~토)
    //    - col (0~weeksToShow): 주차
    //    - nil: 미래 날짜 (아직 도달하지 않은 날)
    //    - DayActivity: 해당 날짜의 학습 데이터 (시간, 집중률, 활동 레벨)
    //
    //    Optional(?)을 사용하는 이유:
    //    마지막 주의 경우 아직 오지 않은 요일은 nil로 표현해야 합니다.
    //    예: 수요일이면 목/금/토는 nil
    @Published var weeklyGrid: [[DayActivity?]] = []
    @Published var selectedDay: DayActivity?
    @Published var todayStudyTime: TimeInterval = 0
    @Published var thisWeekStudyTime: TimeInterval = 0
    @Published var currentStreak: Int = 0

    // MARK: - Dependencies

    // 📚 [의존성 주입 (Dependency Injection)]
    //    sessionStore를 외부에서 주입받습니다 (init 파라미터).
    //    TimerViewModel처럼 내부에서 직접 생성하지 않는 이유:
    //    - 앱 전체에서 하나의 SessionStore를 공유해야 하기 때문입니다.
    //    - TimerViewModel이 세션을 저장하면, 같은 store를 참조하는
    //      DashboardViewModel이 Combine 구독으로 변경을 감지하여 자동 갱신합니다.
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

    // 📚 [Combine의 $sessions Publisher 구독 패턴]
    //    sessionStore.$sessions는 sessions 배열이 변경될 때마다 새 값을 발행합니다.
    //
    //    데이터 흐름:
    //    TimerViewModel.stopTimer()
    //        └── sessionStore.saveSession(session)
    //              └── sessions 배열 변경 (@Published)
    //                    └── $sessions Publisher가 새 값 발행
    //                          └── DashboardViewModel.computeAll() 자동 호출
    //                                └── UI 자동 갱신
    //
    //    이것이 "반응형 프로그래밍(Reactive Programming)"의 핵심입니다.
    //    데이터 변경을 수동으로 알리지 않아도, Publisher-Subscriber 관계만
    //    설정하면 자동으로 전파됩니다.
    //
    //    .sink { [weak self] _ in }
    //    → 여기서 파라미터를 _로 무시하는 이유:
    //      전달되는 값(sessions 배열 자체)은 사용하지 않고,
    //      "변경되었다"는 이벤트만 필요하기 때문입니다.
    //      실제 데이터는 computeAll() 내부에서 sessionStore.sessions에 직접 접근합니다.
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

    // 📚 [잔디 그래프(Contribution Graph) 데이터 생성 알고리즘]
    //    GitHub의 잔디 그래프와 동일한 구조입니다.
    //    핵심 단계:
    //    1. 날짜 범위 계산 (오늘 ~ weeksToShow주 전)
    //    2. 세션을 날짜별로 그룹핑 (Dictionary(grouping:))
    //    3. 각 날짜의 활동 레벨 계산
    //    4. 7행(요일) x N열(주차) 2차원 그리드 생성
    private func computeContributionData() {

        // 📚 [Calendar API - startOfDay(for:)]
        //    startOfDay는 해당 날짜의 00:00:00을 반환합니다.
        //    날짜 비교 시 시/분/초를 무시하고 "같은 날인지"만 비교하기 위해 사용합니다.
        //    예: 2024-03-15 14:30:00 → 2024-03-15 00:00:00
        //    이렇게 정규화하면 같은 날의 세션들을 하나의 키로 그룹핑할 수 있습니다.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeksToShow * 7 + 7 // 여유 포함

        // 📚 [Calendar.date(byAdding:value:to:)]
        //    날짜 연산에 사용하는 Calendar API입니다.
        //    직접 초 단위로 계산하지 않는 이유:
        //    - 서머타임, 윤초 등 복잡한 시간 규칙을 Calendar가 자동 처리합니다.
        //    - 예: 24*60*60을 빼면 서머타임에서 하루가 23시간 또는 25시간일 때 오류 발생
        //    guard let으로 nil 체크: 극단적인 날짜에서는 계산이 실패할 수 있으므로 안전하게 처리
        guard let startDate = calendar.date(byAdding: .day, value: -totalDays, to: today) else { return }

        // 📚 [Dictionary(grouping:by:) - 고차함수]
        //    컬렉션의 요소를 특정 키로 그룹핑하여 딕셔너리를 생성합니다.
        //    결과: [Date: [StudySession]]
        //    예: [2024-03-15: [세션1, 세션2], 2024-03-16: [세션3]]
        //
        //    이 한 줄이 대체하는 것:
        //    var grouped: [Date: [StudySession]] = [:]
        //    for session in recentSessions {
        //        let key = calendar.startOfDay(for: session.startTime)
        //        grouped[key, default: []].append(session)
        //    }
        //    → 고차함수를 사용하면 의도가 더 명확하고 간결합니다.
        let recentSessions = sessionStore.sessions.filter { $0.startTime >= startDate }
        let grouped = Dictionary(grouping: recentSessions) { session -> Date in
            calendar.startOfDay(for: session.startTime)
        }

        // 📚 [reduce를 이용한 합계 계산]
        //    sessions.reduce(0) { $0 + $1.totalDuration }
        //    → 초기값 0부터 시작하여, 각 세션의 totalDuration을 누적합니다.
        //    $0: 누적값(accumulator), $1: 현재 요소(element)
        //    for문으로 합계를 구하는 것과 같지만, 함수형 스타일로 더 간결합니다.
        //
        //    sessions.map { $0.focusRate }.reduce(0, +)
        //    → 먼저 map으로 focusRate만 추출한 배열을 만들고, reduce(0, +)로 합산합니다.
        //    reduce(0, +)는 reduce(0) { $0 + $1 }의 축약형입니다.
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

        // 📚 [2차원 배열 그리드 생성 로직]
        //    잔디 그래프의 레이아웃:
        //
        //         col 0    col 1    col 2   ...  col N (이번 주)
        //    row 0 (일)  [  ]     [  ]     [  ]       [  ]
        //    row 1 (월)  [  ]     [  ]     [  ]       [  ]
        //    row 2 (화)  [  ]     [  ]     [  ]       [  ]
        //    row 3 (수)  [  ]     [  ]     [##]       [nil] ← 미래
        //    row 4 (목)  [  ]     [  ]     [  ]       [nil]
        //    row 5 (금)  [  ]     [  ]     [  ]       [nil]
        //    row 6 (토)  [  ]     [  ]     [  ]       [nil]
        //
        //    핵심 계산:
        //    - gridStartDate: 표시할 첫 번째 일요일 날짜
        //    - dayOffset = col * 7 + row: 그리드 위치 → 날짜 오프셋 변환
        //    - 미래 날짜(date > today)는 nil로 남겨 비워둡니다

        // 📚 [Calendar.component(.weekday, from:)]
        //    .weekday는 요일을 숫자로 반환합니다.
        //    1=일요일, 2=월요일, ..., 7=토요일 (미국 로캘 기준)
        //    이 값으로 "오늘이 그리드의 몇 번째 행(row)에 위치하는지" 계산합니다.
        let todayWeekday = calendar.component(.weekday, from: today) // 1=일, 7=토

        // 그리드 시작점: weeksToShow주 전의 일요일
        let todayDayOffset = todayWeekday - 1 // 일요일부터 오늘까지 오프셋
        let totalColumns = weeksToShow + 1
        guard let gridStartDate = calendar.date(byAdding: .day, value: -(weeksToShow * 7 + todayDayOffset), to: today) else { return }

        // 📚 [Array(repeating:count:)로 2차원 배열 초기화]
        //    Array(repeating: nil, count: totalColumns)로 한 행을 nil로 초기화하고,
        //    그것을 7번 반복하여 7행짜리 2차원 배열을 만듭니다.
        //    주의: 참조 타입이 아닌 값 타입(Optional)이므로 각 행이 독립적으로 복사됩니다.
        //    만약 참조 타입 배열이라면 모든 행이 같은 객체를 가리키는 버그가 발생할 수 있습니다.
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

        // 📚 [Calendar.dateComponents를 이용한 주의 시작일 계산]
        //    dateComponents([.yearForWeekOfYear, .weekOfYear], from:)는
        //    해당 날짜의 "연도-주차" 정보만 추출합니다.
        //    이것을 다시 date(from:)으로 변환하면 해당 주의 시작일(일요일)이 됩니다.
        //
        //    .yearForWeekOfYear: 주 단위 연도 (12월 31일이 다음 해 1주차일 수 있음)
        //    .weekOfYear: 1년 중 몇 번째 주인지
        //
        //    ?? today: nil이 반환되는 극단적인 경우에 대한 안전한 기본값
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        let weekSessions = sessionStore.sessions.filter {
            calendar.startOfDay(for: $0.startTime) >= weekStart
        }
        thisWeekStudyTime = weekSessions.reduce(0) { $0 + $1.totalDuration }

        // 📚 [연속 학습일(Streak) 계산 알고리즘]
        //    GitHub의 "연속 커밋" 계산과 동일한 로직입니다.
        //
        //    알고리즘:
        //    1. 오늘부터 시작하여 하루씩 과거로 이동
        //    2. 해당 날짜에 학습 세션이 있으면 streak += 1
        //    3. 학습 세션이 없으면 중단 (break)
        //    4. 단, "오늘"은 아직 학습하지 않았을 수 있으므로 한 번 더 기회를 줌
        //
        //    예시:
        //    오늘(3/15): 학습 없음 → continue (오늘이니까 스킵)
        //    어제(3/14): 학습 있음 → streak = 1
        //    그제(3/13): 학습 있음 → streak = 2
        //    3/12:      학습 없음 → break
        //    결과: currentStreak = 2
        //
        //    while true + break 패턴:
        //    종료 조건이 복잡할 때 사용하는 패턴입니다.
        //    for문으로는 "오늘은 한 번 건너뛰기" 같은 조건을 표현하기 어렵습니다.
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

    // 📚 [월 레이블 표시 로직]
    //    잔디 그래프 위에 "1월", "2월" 등 월 이름을 표시하는 메서드입니다.
    //    모든 열에 월 이름을 표시하면 복잡하므로, 각 월의 첫 번째 주(1~7일)에만 표시합니다.
    //
    //    DateFormatter 활용:
    //    - locale: 한국어 로캘 설정 → "3월" 형태로 출력
    //    - dateFormat: "M월" → 월 숫자 + "월" 접미사
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
