//
//  ContentView.swift
//  FocusSense
//
//  메인 화면 - 탭 네비게이션
//

// =============================================================================
// 📚 파일 개요: ContentView.swift
// =============================================================================
// 이 파일은 앱의 **메인 탭 네비게이션**을 구성합니다.
//
// 📚 핵심 개념:
//   1. @StateObject vs @ObservedObject:
//      - @StateObject: 이 View가 객체를 **생성하고 소유** (소유자)
//      - @ObservedObject: 외부에서 전달받은 객체를 **관찰** (관찰자)
//      - 잘못 사용하면 View 재생성 시 객체가 사라지는 버그 발생!
//
//   2. 의존성 주입(Dependency Injection) in init():
//      - ViewModel 간 의존성을 init()에서 설정하여 데이터 일관성 보장
//      - _timerViewModel = StateObject(wrappedValue:) 패턴
//
//   3. TabView + tag: SwiftUI의 탭 기반 네비게이션
//   4. @Environment(\.modelContext): SwiftData의 데이터 컨텍스트 접근
//   5. .onAppear에서 configure 호출: 지연 초기화(Lazy Initialization) 패턴
//
// 📚 데이터 흐름:
//   App → ContentView(소유) → TimerViewModel
//                            → DashboardViewModel(sessionStore 공유)
//   ContentView → 각 탭 View (ViewModel 전달)
// =============================================================================

import SwiftUI
import SwiftData

struct ContentView: View {
    // 📚 @StateObject: 이 View가 ViewModel의 **소유자(Owner)** 입니다.
    //    ContentView가 파괴되지 않는 한 이 ViewModel들은 유지됩니다.
    //    중요: @ObservedObject로 바꾸면 SwiftUI가 View를 재생성할 때
    //    ViewModel도 함께 사라져서 상태가 초기화되는 심각한 버그가 발생합니다!
    //    규칙: "처음 만드는 곳에서는 @StateObject, 전달받는 곳에서는 @ObservedObject"
    /// @StateObject: 이 View가 ViewModel을 생성하고 소유함
    @StateObject private var timerViewModel: TimerViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel

    /// @State: View 내부에서 변하는 단순한 값
    @State private var selectedTab = 0

    // 📚 @Environment(\.modelContext): SwiftData의 ModelContext를 환경에서 가져옵니다.
    //    ModelContext는 데이터의 CRUD(생성/조회/수정/삭제) 작업을 수행하는 객체입니다.
    //    앱 최상위에서 .modelContainer()로 주입된 컨테이너의 컨텍스트가 자동으로 전달됩니다.
    //    UIKit의 NSManagedObjectContext에 해당합니다.
    /// SwiftData ModelContext (환경에서 주입)
    @Environment(\.modelContext) private var modelContext

    // 📚 init()에서의 의존성 주입 패턴:
    //    문제: DashboardViewModel이 TimerViewModel의 sessionStore를 필요로 합니다.
    //    해결: init()에서 TimerViewModel을 먼저 만든 후, 그 sessionStore를
    //    DashboardViewModel에 주입합니다.
    //
    //    _timerViewModel = StateObject(wrappedValue:) 구문 설명:
    //    - _timerViewModel: @StateObject 프로퍼티 래퍼의 내부 저장소에 직접 접근
    //    - StateObject(wrappedValue:): 초기값을 설정하는 이니셜라이저
    //    - 이 방식은 init()에서만 사용 가능하며, body에서는 사용하면 안 됩니다!
    //      (body에서 사용하면 매 렌더링마다 새 객체가 생성되는 버그 발생)
    init() {
        let timerVM = TimerViewModel()
        _timerViewModel = StateObject(wrappedValue: timerVM)
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(sessionStore: timerVM.sessionStore))
    }

    var body: some View {
        // 📚 TabView(selection:): 선택된 탭을 $selectedTab과 양방향 바인딩합니다.
        //    selection 값이 변경되면 해당 탭으로 자동 전환됩니다.
        //    외부에서 selectedTab 값을 바꿔도 탭이 전환됩니다 (프로그래밍 방식 전환).
        TabView(selection: $selectedTab) {
            // 홈 (대시보드) 탭
            DashboardView(
                dashboardViewModel: dashboardViewModel,
                selectedTab: $selectedTab // 📚 $: @State의 Binding을 전달합니다. 자식 View에서 탭 전환 가능
            )
            // 📚 .tabItem: 탭 바에 표시될 아이콘과 텍스트를 정의합니다.
            //    SF Symbols 아이콘과 Text를 조합합니다.
            .tabItem {
                Image(systemName: "house.fill")
                Text("홈")
            }
            // 📚 .tag(): 이 탭의 고유 식별자입니다.
            //    selection의 값과 tag 값이 일치하는 탭이 선택됩니다.
            //    예: selectedTab = 0이면 tag(0)인 이 탭이 활성화됩니다.
            .tag(0)

            // 타이머 탭
            TimerView(viewModel: timerViewModel)
                .tabItem {
                    Image(systemName: "timer")
                    Text("타이머")
                }
                .tag(1)

            // 통계 탭 (학습 기록은 통계 내에서 접근)
            AnalyticsView(viewModel: timerViewModel)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("통계")
                }
                .tag(2)

            // 설정 탭
            SettingsView(studyPlanStore: timerViewModel.studyPlanStore)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
                .tag(3)
        }
        // 📚 .tint(): 앱 전체의 강조 색상을 설정합니다.
        //    탭 아이콘의 선택 색상, 버튼 색상 등에 적용됩니다.
        .tint(.orange)
        // 📚 .onAppear: View가 화면에 나타날 때 한 번 실행됩니다.
        //    여기서 SwiftData의 ModelContext를 Store에 주입하는 이유:
        //    - init() 시점에는 @Environment가 아직 주입되지 않았기 때문!
        //    - @Environment는 View가 뷰 계층에 삽입된 후에만 사용 가능합니다.
        //    - 이것이 "지연 초기화(Lazy Initialization)" 패턴입니다.
        //    - init()에서 modelContext를 사용하려 하면 nil이거나 크래시가 발생합니다.
        .onAppear {
            // SwiftData ModelContext를 Store에 주입
            timerViewModel.sessionStore.configure(with: modelContext)
            timerViewModel.studyPlanStore.configure(with: modelContext)
        }
    }
}

// MARK: - Preview

// 📚 #Preview: Xcode의 Canvas에서 실시간 미리보기를 제공합니다.
//    .modelContainer(for:inMemory: true): 미리보기용 임시 데이터베이스를 생성합니다.
//    inMemory: true이므로 디스크에 저장되지 않고 메모리에서만 동작합니다.
//    이렇게 하면 실제 데이터에 영향 없이 안전하게 미리보기를 확인할 수 있습니다.
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [StudySession.self, FocusRecord.self, StudyPlan.self], inMemory: true)
}
