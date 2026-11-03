//
//  ContentView.swift
//  Orot
//
//  하단 탭 3개(집중 / 밤하늘 / 기록). 설정은 집중 탭 오른쪽 위 아이콘으로 들어갑니다.
//  세션과 휴식 중에는 탭바 대신 전체 화면 세션을 띄웁니다.
//

import SwiftUI
import SwiftData

enum Tab: CaseIterable {
    case focus
    case nightSky
    case records

    var title: String {
        switch self {
        case .focus: return "집중"
        case .nightSky: return "밤하늘"
        case .records: return "기록"
        }
    }
}

struct ContentView: View {
    @StateObject private var timerViewModel = TimerViewModel()
    @State private var selectedTab: Tab = .focus
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .focus:
                    FocusSetupView(viewModel: timerViewModel, subjectStore: timerViewModel.subjectStore, sessionStore: timerViewModel.sessionStore)
                case .nightSky:
                    NightSkyView(sessionStore: timerViewModel.sessionStore)
                case .records:
                    AnalyticsView(viewModel: timerViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            OrotTabBar(selection: $selectedTab)
        }
        .background(OrotColor.skyNight.ignoresSafeArea())
        .tint(OrotColor.accent)
        .fullScreenCover(isPresented: $timerViewModel.isSessionPresented) {
            SessionView(viewModel: timerViewModel) {
                selectedTab = .nightSky
            }
        }
        .onChange(of: timerViewModel.isSessionPresented) { _, presented in
            OrientationLock.allowLandscape(presented)
        }
        .onAppear {
            timerViewModel.sessionStore.configure(with: modelContext)
            timerViewModel.studyPlanStore.configure(with: modelContext)
            timerViewModel.subjectStore.configure(with: modelContext)
            Task {
                timerViewModel.sessionStore.loadAllSessions()
            }
        }
    }
}

// MARK: - Tab Bar
private struct OrotTabBar: View {
    @Binding var selection: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    Text(tab.title)
                        .font(OrotFont.regular(13))
                        .foregroundStyle(selection == tab ? OrotColor.textPrimary : OrotColor.textCaption)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
                        .padding(.top, 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .background(OrotColor.skyNight.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(OrotColor.hairline).frame(height: 1)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [StudySession.self, FocusRecord.self, StudyPlan.self, FocusSubject.self], inMemory: true)
}
