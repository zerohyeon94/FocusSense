//
//  StudySessionStore.swift
//  FocusSense
//
//  학습 세션 저장/불러오기 서비스 (SwiftData 기반)
//

import Foundation
import SwiftData

// MARK: - Study Session Store
@MainActor
final class StudySessionStore: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var sessions: [StudySession] = []

    // MARK: - SwiftData
    private var modelContext: ModelContext?

    // MARK: - Initialization
    init() {
        print("✅ StudySessionStore 초기화 (SwiftData)")
    }

    // MARK: - Configure
    /// ContentView.onAppear에서 ModelContext를 주입
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadAllSessions()
        migrateJSONDataIfNeeded()
        print("✅ StudySessionStore configured: \(sessions.count)개 세션 로드")
    }

    // MARK: - Save Session
    func saveSession(_ session: StudySession) {
        guard let modelContext else {
            print("❌ ModelContext가 설정되지 않았습니다")
            return
        }

        guard session.endTime != nil else {
            print("⚠️ 종료되지 않은 세션은 저장할 수 없습니다")
            return
        }

        guard !session.focusRecords.isEmpty else {
            print("⚠️ 기록이 없는 세션은 저장하지 않습니다")
            return
        }

        // 이미 context에 있지 않으면 insert
        modelContext.insert(session)

        do {
            try modelContext.save()
            loadAllSessions()
            print("✅ 세션 저장 완료: \(session.formattedTotalDuration)")
        } catch {
            print("❌ 세션 저장 실패: \(error)")
        }
    }

    // MARK: - Load All Sessions
    func loadAllSessions() {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<StudySession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            sessions = try modelContext.fetch(descriptor)
        } catch {
            print("❌ 세션 로드 실패: \(error)")
            sessions = []
        }
    }

    // MARK: - Delete Session
    func deleteSession(_ session: StudySession) {
        guard let modelContext else { return }

        modelContext.delete(session)

        do {
            try modelContext.save()
            sessions.removeAll { $0.id == session.id }
            print("✅ 세션 삭제 완료")
        } catch {
            print("❌ 세션 삭제 실패: \(error)")
        }
    }

    // MARK: - Query Helpers

    /// 오늘의 세션들
    var todaySessions: [StudySession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions.filter { calendar.startOfDay(for: $0.startTime) == today }
    }

    /// 특정 날짜의 세션들
    func sessions(for date: Date) -> [StudySession] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return sessions.filter { calendar.startOfDay(for: $0.startTime) == targetDay }
    }

    /// 최근 N일간의 세션들
    func recentSessions(days: Int) -> [StudySession] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
        return sessions.filter { $0.startTime >= startDate }
    }

    /// 오늘의 총 학습 시간
    var todayTotalDuration: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.totalDuration }
    }

    /// 오늘의 평균 집중률
    var todayAverageFocusRate: Double {
        let today = todaySessions
        guard !today.isEmpty else { return 0 }
        return today.map { $0.focusRate }.reduce(0, +) / Double(today.count)
    }

    // MARK: - JSON → SwiftData Migration
    private func migrateJSONDataIfNeeded() {
        guard let modelContext else { return }

        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sessionsDir = documentsDir.appendingPathComponent("StudySessions", isDirectory: true)

        guard fileManager.fileExists(atPath: sessionsDir.path) else { return }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: sessionsDir,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }

            guard !fileURLs.isEmpty else { return }

            print("🔄 JSON 데이터 마이그레이션 시작: \(fileURLs.count)개 파일")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            var migratedCount = 0
            for url in fileURLs {
                do {
                    let data = try Data(contentsOf: url)
                    let legacySession = try decoder.decode(LegacyStudySession.self, from: data)

                    // SwiftData 모델로 변환
                    let session = StudySession(
                        id: legacySession.id,
                        startTime: legacySession.startTime
                    )
                    session.endTime = legacySession.endTime

                    for legacyRecord in legacySession.focusRecords {
                        let record = FocusRecord(
                            id: legacyRecord.id,
                            timestamp: legacyRecord.timestamp,
                            focusLevel: legacyRecord.focusLevel,
                            duration: legacyRecord.duration
                        )
                        record.session = session
                        session.focusRecords.append(record)
                    }

                    modelContext.insert(session)
                    migratedCount += 1
                } catch {
                    print("⚠️ JSON 파일 마이그레이션 실패: \(url.lastPathComponent) - \(error)")
                }
            }

            if migratedCount > 0 {
                try modelContext.save()
                loadAllSessions()

                // 마이그레이션 완료 후 JSON 디렉토리 삭제
                try? fileManager.removeItem(at: sessionsDir)
                print("✅ JSON 마이그레이션 완료: \(migratedCount)개 세션")
            }
        } catch {
            print("❌ JSON 마이그레이션 실패: \(error)")
        }
    }
}

// MARK: - Legacy Models (JSON 마이그레이션용)
private struct LegacyStudySession: Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var focusRecords: [LegacyFocusRecord]
}

private struct LegacyFocusRecord: Codable {
    let id: UUID
    let timestamp: Date
    let focusLevel: FocusLevel
    let duration: TimeInterval
}
