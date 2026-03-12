//
//  DashboardView.swift
//  FocusSense
//
//  대시보드 홈 화면 - 인사말 + 잔디 그래프 + 빠른 시작
//

// =============================================================================
// 📚 파일 개요: DashboardView.swift
// =============================================================================
// 이 파일은 앱의 **홈 대시보드 화면**을 구성합니다.
//
// 📚 핵심 개념:
//   1. @ObservedObject vs @StateObject:
//      - 여기서는 @ObservedObject를 사용합니다.
//      - ContentView가 소유(@StateObject)한 ViewModel을 전달받아 관찰만 합니다.
//
//   2. @Binding: 부모 View의 @State를 자식 View에서 읽고 쓸 수 있게 연결
//      - DashboardView에서 selectedTab을 변경하면 ContentView의 탭이 전환됩니다.
//
//   3. NavigationStack: iOS 16+에서 도입된 새로운 네비게이션 컨테이너
//   4. ScrollView + VStack: 스크롤 가능한 수직 레이아웃
//   5. Computed Property로 시간대별 인사말 로직 분리
//   6. View 분리 패턴: 100줄 이상이면 별도의 struct로 분리 (코드 가독성)
// =============================================================================

import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    // 📚 @ObservedObject: 외부에서 전달받은 ObservableObject를 **관찰**합니다.
    //    ContentView에서 @StateObject로 생성한 dashboardViewModel을 여기서 관찰합니다.
    //    이 View는 ViewModel을 소유하지 않으므로, View가 재생성되어도
    //    ViewModel은 ContentView에 의해 유지됩니다.
    //    주의: @StateObject로 잘못 선언하면 새 인스턴스가 생성되어 데이터 불일치 발생!
    @ObservedObject var dashboardViewModel: DashboardViewModel

    // 📚 @Binding: 부모 View의 @State와 **양방향 연결**을 만듭니다.
    //    읽기: 부모의 현재 selectedTab 값을 읽을 수 있음
    //    쓰기: 값을 변경하면 부모의 @State도 함께 변경됨 → 탭 전환 발생
    //    활용: "빠른 시작" 버튼을 눌렀을 때 selectedTab = 1로 변경하여 타이머 탭으로 이동
    //    $접두사로 Binding을 전달: DashboardView(selectedTab: $selectedTab)
    @Binding var selectedTab: Tab

    var body: some View {
        // 📚 NavigationStack: iOS 16+에서 NavigationView를 대체하는 새로운 컨테이너입니다.
        //    장점:
        //    - NavigationPath와 결합하여 프로그래밍 방식의 네비게이션 지원
        //    - .navigationDestination(for:)으로 타입 기반 네비게이션 가능
        //    - 더 나은 성능과 메모리 관리
        //    기존 NavigationView는 deprecated되었으므로 NavigationStack 사용을 권장합니다.
        NavigationStack {
            // 📚 ScrollView: 콘텐츠가 화면을 넘어갈 때 스크롤을 가능하게 합니다.
            //    기본값은 수직(.vertical) 스크롤입니다.
            //    List와 달리 자유로운 레이아웃이 가능하여 대시보드에 적합합니다.
            ScrollView {
                // 📚 VStack(spacing:): 수직으로 뷰를 쌓는 컨테이너입니다.
                //    spacing: 24로 각 카드 사이에 일정한 간격을 줍니다.
                //    일관된 spacing으로 시각적 리듬감을 만들어 좋은 UI를 구성합니다.
                VStack(spacing: 24) {
                    // 인사말
                    GreetingHeader()

                    // 요약 통계
                    QuickStatsCard(
                        streak: dashboardViewModel.currentStreak,
                        todayTime: dashboardViewModel.todayStudyTime,
                        weekTime: dashboardViewModel.thisWeekStudyTime
                    )

                    // 잔디 그래프
                    ContributionGraphCard(viewModel: dashboardViewModel)

                    // 📚 클로저를 통한 액션 전달:
                    //    QuickStartCard에 탭 전환 로직을 클로저로 전달합니다.
                    //    QuickStartCard는 "버튼이 눌렸을 때 무엇을 할지"를 모르고,
                    //    외부에서 주입받은 클로저를 실행할 뿐입니다.
                    //    이 패턴으로 QuickStartCard의 재사용성이 높아집니다.
                    // 빠른 시작
                    QuickStartCard {
                        selectedTab = .timer // 📚 @Binding을 통해 부모의 탭을 변경 → 타이머 탭으로 이동
                    }
                }
                .padding()
            }
            .background(Color(hex: "0f0f1a"))
            // 📚 .navigationTitle: NavigationStack의 상단에 제목을 표시합니다.
            //    .large: 큰 제목 스타일로, 스크롤 시 자동으로 작은 제목으로 축소됩니다.
            .navigationTitle("ZipJoong")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
