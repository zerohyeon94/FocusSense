//
//  HistoryView.swift
//  FocusSense
//
//  학습 기록 히스토리 화면
//

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
                formatter.dateFormat = "EEEE"
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
