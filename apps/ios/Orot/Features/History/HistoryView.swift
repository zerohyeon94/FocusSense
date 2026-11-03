//
//  HistoryView.swift
//  FocusSense
//
//  학습 기록 히스토리 화면
//

// ============================================================================
// 📚 [파일 개요] HistoryView - 학습 기록 히스토리 화면
// ============================================================================
//
// 📚 [Dictionary(grouping:by:) - 날짜별 그룹화]
//   Swift 표준 라이브러리의 Dictionary(grouping:by:)를 사용하여
//   세션 배열을 날짜별로 그룹화합니다.
//   예: [StudySession] → [Date: [StudySession]]
//   이를 통해 "오늘", "어제", "3월 3일" 등 날짜 섹션별로 세션을 표시합니다.
//
// 📚 [.onDelete - 스와이프 삭제]
//   List의 ForEach에 .onDelete(perform:)를 추가하면
//   사용자가 행을 왼쪽으로 스와이프하여 삭제할 수 있습니다.
//   IndexSet을 받아 해당 인덱스의 항목을 데이터 소스에서 제거합니다.
//
// 📚 [NavigationLink - 상세 화면 이동]
//   각 세션 행을 NavigationLink로 감싸면, 탭 시 SessionDetailView로
//   푸시 내비게이션됩니다. NavigationStack 안에서 자동으로 동작합니다.
//
// 📚 [FocusRateCircle - 재사용 가능한 원형 프로그레스]
//   집중률을 원형 프로그레스 바로 표시하는 컴포넌트입니다.
//   Circle().trim(from:to:)으로 호(arc)를 그리고,
//   중앙에 퍼센트 텍스트를 오버레이합니다.
//   여러 화면에서 재사용되는 공통 UI 컴포넌트 패턴입니다.
//
// ============================================================================

import SwiftUI

struct HistoryView: View {
    @ObservedObject var sessionStore: StudySessionStore

    var body: some View {
        NavigationStack {
            Group {
                if sessionStore.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .background(Color(hex: "0f0f1a"))
            .navigationTitle("학습 기록")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("아직 학습 기록이 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("타이머를 시작하고 학습을 완료하면\n여기에 기록이 저장됩니다")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Session List
    private var sessionList: some View {
        List {
            ForEach(groupedSessions, id: \.key) { dateString, sessions in
                Section {
                    ForEach(sessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            SessionRowView(session: session)
                        }
                    }
                    .onDelete { indexSet in
                        deleteSessions(from: sessions, at: indexSet)
                    }
                } header: {
                    HStack {
                        Text(dateString)
                        Spacer()
                        Text("\(sessions.count)회")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouped Sessions by Date
    private var groupedSessions: [(key: String, value: [StudySession])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")

        let grouped = Dictionary(grouping: sessionStore.sessions) { session -> String in
            let date = session.startTime
            if calendar.isDateInToday(date) {
                return "오늘"
            } else if calendar.isDateInYesterday(date) {
                return "어제"
            } else if let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: Date())).day, daysAgo < 7 {
                formatter.dateFormat = "EEEE" // 요일
                return formatter.string(from: date)
            } else {
                formatter.dateFormat = "M월 d일 (E)"
                return formatter.string(from: date)
            }
        }

        // 날짜 순서 정렬 (최신 먼저)
        return grouped.sorted { pair1, pair2 in
            let date1 = pair1.value.first?.startTime ?? Date.distantPast
            let date2 = pair2.value.first?.startTime ?? Date.distantPast
            return date1 > date2
        }
    }

    // MARK: - Delete
    private func deleteSessions(from sessions: [StudySession], at offsets: IndexSet) {
        for index in offsets {
            sessionStore.deleteSession(sessions[index])
        }
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: StudySession

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    var body: some View {
        HStack(spacing: 14) {
            // 집중률 원형 인디케이터
            FocusRateCircle(rate: session.focusRate)

            VStack(alignment: .leading, spacing: 4) {
                // 시간 범위
                HStack(spacing: 4) {
                    Text(timeFormatter.string(from: session.startTime))
                    Text("~")
                        .foregroundColor(.secondary)
                    if let endTime = session.endTime {
                        Text(timeFormatter.string(from: endTime))
                    }
                }
                .font(.subheadline.weight(.medium))

                // 학습 시간
                Text(session.formattedTotalDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 이벤트 요약
            VStack(alignment: .trailing, spacing: 4) {
                if session.drowsinessCount > 0 {
                    Label("\(session.drowsinessCount)", systemImage: "moon.zzz.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                if session.unfocusedCount > 0 {
                    Label("\(session.unfocusedCount)", systemImage: "eye.slash.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Focus Rate Circle
struct FocusRateCircle: View {
    let rate: Double

    private var color: Color {
        switch rate {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
                .frame(width: 44, height: 44)

            Circle()
                .trim(from: 0, to: min(rate / 100, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))

            Text(String(format: "%.0f", rate))
                .font(.caption2.bold())
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView(sessionStore: StudySessionStore())
        .preferredColorScheme(.dark)
}
