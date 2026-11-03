//
//  StudySessionStore.swift
//  FocusSense
//
//  학습 세션 저장/불러오기 서비스 (SwiftData 기반)
//

// ============================================================================
// 📚 파일 개요: StudySessionStore
// ============================================================================
// 이 파일은 학습 세션 데이터를 SwiftData로 관리하는 "Store" 서비스입니다.
//
// 📚 핵심 개념:
// 1. Store 패턴 — 데이터의 CRUD(생성/조회/수정/삭제)를 하나의 클래스에서 중앙 관리
//    → ViewModel이 직접 DB에 접근하지 않고, Store를 통해 간접적으로 접근
//    → 데이터 접근 로직이 한곳에 모여 있어 유지보수가 쉬움
//
// 2. SwiftData — Apple의 최신 데이터 영속화 프레임워크 (Core Data의 후속)
//    → @Model 매크로로 모델을 정의하면, 자동으로 SQLite에 저장/불러오기
//    → ModelContext를 통해 CRUD 작업을 수행
//
// 3. JSON → SwiftData 마이그레이션
//    → 기존 JSON 파일로 저장하던 데이터를 SwiftData로 옮기는 일회성 작업
//    → 앱 업데이트 시 사용자 데이터를 잃지 않기 위해 필수적인 패턴
//
// 📚 아키텍처 흐름:
//    View (SwiftUI) → ViewModel → StudySessionStore → SwiftData (SQLite)
// ============================================================================

import Foundation
import SwiftData

// MARK: - Study Session Store

// 📚 @MainActor란?
// Swift 동시성(Concurrency)에서 "이 클래스의 모든 프로퍼티와 메서드는 메인 스레드에서 실행된다"는 보장.
// 왜 필요한가?
//   - @Published 프로퍼티가 변경되면 SwiftUI가 UI를 다시 그림
//   - UI 업데이트는 반드시 메인 스레드에서 해야 함 (아니면 크래시)
//   - @MainActor를 붙이면 컴파일러가 메인 스레드 접근을 자동으로 보장해줌
//   - DispatchQueue.main.async 대신 Swift 동시성의 현대적인 방식
//
// 📚 final이란?
// 이 클래스를 상속할 수 없게 만듦. 왜?
//   - Store는 앱에서 하나만 존재해야 하는 서비스 → 상속으로 변형될 이유 없음
//   - final을 붙이면 컴파일러가 메서드 호출을 최적화(static dispatch) → 성능 향상
//
// 📚 ObservableObject 프로토콜이란?
// SwiftUI의 "데이터 바인딩" 시스템의 핵심.
//   - 이 프로토콜을 채택하면, 내부 @Published 프로퍼티가 변경될 때
//     이 객체를 관찰하는 모든 SwiftUI View에 자동으로 "다시 그려라!" 신호를 보냄
//   - View에서는 @StateObject 또는 @ObservedObject로 이 객체를 구독
@MainActor
final class StudySessionStore: ObservableObject {

    // MARK: - Published Properties

    // 📚 @Published + private(set) 조합 패턴
    //
    // @Published: 이 프로퍼티가 변경되면 SwiftUI View에 자동 알림
    //   → sessions 배열이 바뀔 때마다 이를 관찰하는 View가 자동 리렌더링
    //
    // private(set): "읽기는 외부에서 가능, 쓰기는 내부에서만 가능"
    //   → 외부에서 store.sessions으로 읽을 수 있지만
    //   → store.sessions = [...] 으로 직접 변경은 불가
    //   → 데이터 변경은 반드시 saveSession(), deleteSession() 등의 메서드를 통해서만 가능
    //   → 이렇게 하면 데이터 무결성을 보장할 수 있음 (캡슐화의 핵심)
    @Published private(set) var sessions: [StudySession] = []

    // MARK: - SwiftData

    // 📚 ModelContext란?
    // SwiftData에서 데이터를 조작하는 "작업 공간" (Core Data의 NSManagedObjectContext와 동일)
    //   - insert: 새 데이터 추가
    //   - delete: 데이터 삭제
    //   - save: 변경 사항을 실제 저장소(SQLite)에 반영
    //   - fetch: 저장소에서 데이터 조회
    //
    // 📚 왜 Optional(?)인가?
    // init() 시점에는 아직 ModelContext가 준비되지 않았기 때문.
    // SwiftData의 ModelContainer는 SwiftUI의 App 레벨에서 생성되고,
    // ModelContext는 그 이후에 주입(inject)됨. → "지연 주입(Lazy Injection)" 패턴
    private var modelContext: ModelContext?

    // MARK: - Initialization
    init() {
        print("✅ StudySessionStore 초기화 (SwiftData)")
    }

    // MARK: - Configure

    // 📚 의존성 주입(Dependency Injection) 패턴
    // ModelContext를 init()에서 받지 않고, configure()로 나중에 주입하는 이유:
    //   1. SwiftUI의 @StateObject는 init()에서 매개변수를 전달하기 어려움
    //   2. ModelContext는 SwiftUI 환경(@Environment)에서 제공되므로,
    //      View가 렌더링된 후(onAppear)에야 접근 가능
    //   3. 따라서 "2단계 초기화": init()으로 객체 생성 → configure()로 의존성 주입
    /// ContentView.onAppear에서 ModelContext를 주입
    func configure(with context: ModelContext) {
        self.modelContext = context
        migrateJSONDataIfNeeded()
    }

    // MARK: - Save Session

    // 📚 Guard 문을 이용한 방어적 프로그래밍(Defensive Programming)
    // 여러 개의 guard로 유효성을 순서대로 검증:
    //   1. modelContext가 있는지 (설정 여부)
    //   2. endTime이 있는지 (세션 종료 여부)
    //   3. focusRecords가 비어있지 않은지 (유의미한 데이터 여부)
    // → 하나라도 실패하면 early return으로 즉시 종료
    // → 이 패턴은 "실패 조건을 먼저 걸러내고, 성공 경로만 남기는" 코드를 만듦
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

        // 📚 do-catch: Swift의 에러 처리 패턴
        // modelContext.save()는 throws로 선언된 메서드 → 실패할 수 있음
        // try로 호출하고, 실패하면 catch 블록에서 에러를 처리
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
            // 📚 FetchDescriptor — SwiftData의 쿼리 빌더
            // SQL의 "SELECT * FROM StudySession ORDER BY startTime DESC"와 동일
            //
            // FetchDescriptor<StudySession>: 어떤 모델을 조회할지 지정 (제네릭 타입)
            // SortDescriptor(\.startTime, order: .reverse): 최신순 정렬
            //   → \.startTime은 KeyPath 문법. StudySession의 startTime 프로퍼티를 가리킴
            //   → .reverse는 내림차순(최신이 먼저)
            //
            // 📚 타입 안전성(Type Safety)의 장점:
            // SQL 쿼리는 문자열이라 오타가 있어도 컴파일 시 알 수 없지만,
            // FetchDescriptor는 Swift 타입 시스템으로 컴파일 타임에 오류를 잡아줌
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
            // 📚 로컬 배열도 함께 업데이트하는 이유:
            // modelContext.save()로 DB에서는 삭제되었지만,
            // @Published sessions 배열에서도 제거해야 UI가 즉시 반영됨
            // loadAllSessions()를 호출해도 되지만, removeAll이 더 효율적
            sessions.removeAll { $0.id == session.id }
            print("✅ 세션 삭제 완료")
        } catch {
            print("❌ 세션 삭제 실패: \(error)")
        }
    }

    // MARK: - Query Helpers

    // 📚 Computed Property (연산 프로퍼티) 패턴
    // var todaySessions는 저장된 값이 아니라, 호출될 때마다 계산되는 프로퍼티.
    // sessions 배열이 변경될 때마다 최신 결과를 반환.
    // 메서드 대신 연산 프로퍼티를 사용하면:
    //   - store.todaySessions() 대신 store.todaySessions로 접근 (더 자연스러운 API)
    //   - "매개변수 없이 데이터를 조회하는 것"에 적합한 패턴

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
        // 📚 reduce — 함수형 프로그래밍의 "접기(fold)" 연산
        // 배열의 모든 요소를 하나의 값으로 합침
        // reduce(초기값) { 누적값, 현재요소 in 새_누적값 }
        // 여기서는: 0부터 시작해서, 각 세션의 totalDuration을 계속 더해나감
        // $0 = 지금까지 누적된 합, $1 = 현재 세션
        todaySessions.reduce(0) { $0 + $1.totalDuration }
    }

    /// 오늘의 평균 집중률
    var todayAverageFocusRate: Double {
        let today = todaySessions
        guard !today.isEmpty else { return 0 }
        // 📚 map + reduce 체인: 함수형 프로그래밍의 대표적인 패턴
        // .map { $0.focusRate } → 세션 배열을 집중률 배열로 변환 [0.8, 0.6, 0.9]
        // .reduce(0, +) → 모든 값을 더함 (0 + 0.8 + 0.6 + 0.9 = 2.3)
        // / Double(today.count) → 평균 계산 (2.3 / 3 = 0.766...)
        return today.map { $0.focusRate }.reduce(0, +) / Double(today.count)
    }

    // MARK: - JSON → SwiftData Migration

    // 📚 마이그레이션(Migration) 패턴
    // 앱이 이전 버전에서 JSON 파일로 세션을 저장했다면,
    // SwiftData로 전환하면서 기존 데이터를 옮겨야 함.
    // 이 메서드는 다음을 수행:
    //   1. JSON 파일이 있는지 확인 → 없으면 아무것도 안 함 (이미 마이그레이션됨)
    //   2. 각 JSON 파일을 읽어서 → LegacyStudySession으로 디코딩
    //   3. SwiftData 모델(StudySession)로 변환 후 저장
    //   4. 마이그레이션 완료 후 원본 JSON 디렉토리 삭제
    //
    // 📚 왜 private인가?
    // 마이그레이션은 앱 내부 로직이며, 외부에서 호출할 이유가 없음.
    // configure() 내부에서만 자동으로 실행됨.
    private func migrateJSONDataIfNeeded() {
        guard let modelContext else { return }

        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sessionsDir = documentsDir.appendingPathComponent("StudySessions", isDirectory: true)

        // 📚 "IfNeeded" 패턴 — 멱등성(Idempotency) 보장
        // JSON 디렉토리가 존재하지 않으면 이미 마이그레이션이 완료된 것이므로 종료.
        // 이 메서드를 여러 번 호출해도 안전함 (한 번만 실행되고 그 후에는 아무것도 안 함)
        guard fileManager.fileExists(atPath: sessionsDir.path) else { return }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: sessionsDir,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }

            guard !fileURLs.isEmpty else { return }

            print("🔄 JSON 데이터 마이그레이션 시작: \(fileURLs.count)개 파일")

            let decoder = JSONDecoder()
            // 📚 ISO 8601: 국제 표준 날짜 형식 (예: "2024-01-15T09:30:00Z")
            // JSON에서 Date를 문자열로 저장할 때 가장 널리 쓰이는 형식
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
                    // 📚 개별 파일 실패 시에도 전체 마이그레이션은 계속 진행
                    // 하나의 파일이 깨져 있더라도 나머지 파일은 정상 마이그레이션
                    print("⚠️ JSON 파일 마이그레이션 실패: \(url.lastPathComponent) - \(error)")
                }
            }

            if migratedCount > 0 {
                try modelContext.save()
                loadAllSessions()

                // 📚 try? — 에러를 무시하는 패턴
                // 디렉토리 삭제가 실패해도 앱 동작에 지장 없음
                // (다음 실행 시 JSON이 남아 있으면 "이미 마이그레이션된 데이터"를 중복 삽입할 수 있지만,
                //  UUID로 식별되므로 실질적인 문제는 적음)
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

// 📚 private struct — 파일 내부에서만 사용되는 타입
// 이 구조체들은 마이그레이션에만 사용되며, 외부에서 알 필요가 없음.
// private을 붙이면:
//   1. 다른 파일에서 접근 불가 → 불필요한 의존성 생성을 방지
//   2. "이건 내부 구현 세부사항"이라는 의도를 명확히 전달
//   3. 나중에 마이그레이션이 더 이상 필요 없으면, 이 코드를 안전하게 삭제할 수 있음
//
// 📚 Codable 프로토콜: JSON ↔ Swift 객체 간의 자동 변환을 제공
// Codable = Encodable + Decodable (인코딩 + 디코딩 모두 가능)
// 구조체의 프로퍼티 이름과 JSON 키가 같으면 별도 설정 없이 자동 매핑
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
