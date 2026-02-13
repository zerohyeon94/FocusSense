//
//  StudySessionStore.swift
//  FocusSense
//
//  학습 세션 저장/불러오기 서비스 (JSON 파일 기반)
//

import Foundation

// MARK: - Study Session Store
@MainActor
final class StudySessionStore: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var sessions: [StudySession] = []

    // MARK: - File Storage
    private let fileManager = FileManager.default

    private var storageDirectory: URL {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sessionsDir = documentsDir.appendingPathComponent("StudySessions", isDirectory: true)

        if !fileManager.fileExists(atPath: sessionsDir.path) {
            try? fileManager.createDirectory(at: sessionsDir, withIntermediateDirectories: true)
        }

        return sessionsDir
    }

    // MARK: - Initialization
    init() {
        loadAllSessions()
        print("✅ StudySessionStore 초기화: \(sessions.count)개 세션 로드")
    }

    // MARK: - Save Session
    func saveSession(_ session: StudySession) {
        guard session.endTime != nil else {
            print("⚠️ 종료되지 않은 세션은 저장할 수 없습니다")
            return
        }

        guard !session.focusRecords.isEmpty else {
            print("⚠️ 기록이 없는 세션은 저장하지 않습니다")
            return
        }

        let fileName = "\(session.id.uuidString).json"
        let fileURL = storageDirectory.appendingPathComponent(fileName)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(session)
            try data.write(to: fileURL, options: .atomic)

            // 메모리 목록 업데이트
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index] = session
            } else {
                sessions.append(session)
                sessions.sort { $0.startTime > $1.startTime }
            }

            print("✅ 세션 저장 완료: \(session.formattedTotalDuration)")
        } catch {
            print("❌ 세션 저장 실패: \(error)")
        }
    }

    // MARK: - Load All Sessions
    func loadAllSessions() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: storageDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            var loaded: [StudySession] = []
            for url in fileURLs {
                do {
                    let data = try Data(contentsOf: url)
                    let session = try decoder.decode(StudySession.self, from: data)
                    loaded.append(session)
                } catch {
                    print("⚠️ 세션 파일 로드 실패: \(url.lastPathComponent) - \(error)")
                }
            }

            sessions = loaded.sorted { $0.startTime > $1.startTime }
        } catch {
            print("❌ 세션 디렉토리 읽기 실패: \(error)")
            sessions = []
        }
    }

    // MARK: - Delete Session
    func deleteSession(_ session: StudySession) {
        let fileName = "\(session.id.uuidString).json"
        let fileURL = storageDirectory.appendingPathComponent(fileName)

        do {
            try fileManager.removeItem(at: fileURL)
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
}
