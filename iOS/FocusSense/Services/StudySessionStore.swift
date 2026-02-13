//
//  StudySessionStore.swift
//  FocusSense
//
//  학습 세션 저장/불러오기 서비스 (SwiftData 기반)
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Study Session Store
@MainActor
final class StudySessionStore: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var sessions: [StudySession] = []

    // MARK: - SwiftData
    private var modelContext: ModelContext?

    // MARK: - Initialization
    init() {
        // ModelContext는 나중에 configure()로 주입됨
        print("✅ StudySessionStore 초기화 (SwiftData)")
    }

    // MARK: - Configure with ModelContext
    /// App 시작 시 ModelContainer에서 ModelContext를 주입받음
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAllSessions()
        migrateJSONDataIfNeeded()
        print("✅ StudySessionStore 설정 완료: \(sessions.count)개 세션 로드")
    }

    // MARK: - Save Session
    func saveSession(_ session: StudySession) {
        guard let modelContext = modelContext else {
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

        // SwiftData에 삽입
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
        guard let modelContext = modelContext else { return }

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
        guard let modelContext = modelContext else {
            print("❌ ModelContext가 설정되지 않았습니다")
            return
        }

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

    // MARK: - JSON Migration (기존 JSON 데이터 → SwiftData 마이그레이션)
    private func migrateJSONDataIfNeeded() {
        guard let modelContext = modelContext else { return }

        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sessionsDir = documentsDir.appendingPathComponent("StudySessions", isDirectory: true)

        // JSON 디렉토리가 없으면 마이그레이션 불필요
        guard fileManager.fileExists(atPath: sessionsDir.path) else { return }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: sessionsDir,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }

            guard !fileURLs.isEmpty else { return }

            print("🔄 JSON → SwiftData 마이그레이션 시작: \(fileURLs.count)개 파일")

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            var migratedCount = 0

            for url in fileURLs {
                do {
                    let data = try Data(contentsOf: url)
                    let jsonSession = try decoder.decode(LegacyStudySession.self, from: data)

                    // 중복 확인: 이미 SwiftData에 같은 ID 세션이 있으면 스킵
                    let existingDescriptor = FetchDescriptor<StudySession>(
                        predicate: #Predicate { $0.id == jsonSession.id }
                    )
                    let existing = try modelContext.fetch(existingDescriptor)
                    guard existing.isEmpty else { continue }

                    // SwiftData 모델로 변환
                    let session = StudySession(
                        id: jsonSession.id,
                        startTime: jsonSession.startTime
                    )
                    session.endTime = jsonSession.endTime

                    modelContext.insert(session)

                    // FocusRecord 변환
                    for record in jsonSession.focusRecords {
                        let focusRecord = FocusRecord(
                            id: record.id,
                            timestamp: record.timestamp,
                            focusLevel: record.focusLevel,
                            duration: record.duration,
                            focusScore: record.focusScore
                        )
                        focusRecord.session = session
                        session.focusRecords.append(focusRecord)
                    }

                    migratedCount += 1
                } catch {
                    print("⚠️ JSON 마이그레이션 실패: \(url.lastPathComponent) - \(error)")
                }
            }

            if migratedCount > 0 {
                try modelContext.save()
                loadAllSessions()
                print("✅ JSON → SwiftData 마이그레이션 완료: \(migratedCount)개 세션")

                // 마이그레이션 완료 후 JSON 디렉토리 백업 이동
                let backupDir = documentsDir.appendingPathComponent("StudySessions_backup", isDirectory: true)
                try? fileManager.moveItem(at: sessionsDir, to: backupDir)
                print("✅ JSON 파일 백업 완료: StudySessions_backup/")
            }
        } catch {
            print("❌ JSON 마이그레이션 오류: \(error)")
        }
    }
}

// MARK: - Legacy Models (JSON 마이그레이션용)
/// 기존 JSON 파일의 Codable 구조체 (마이그레이션 전용)
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
    let focusScore: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        focusLevel = try container.decode(FocusLevel.self, forKey: .focusLevel)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        focusScore = try container.decodeIfPresent(Double.self, forKey: .focusScore) ?? 0
    }
}
