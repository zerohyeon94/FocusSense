//
//  StudySession.swift
//  FocusSense
//
//  학습 세션 기록 모델 (SwiftData)
//

/// ============================================================
/// 📚 학습 포인트: SwiftData의 @Model 매크로
/// ============================================================
///
/// SwiftData는 Apple이 iOS 17에서 도입한 데이터 영속화 프레임워크입니다.
/// 기존 CoreData를 대체하며, 더 간결한 Swift 네이티브 문법을 사용합니다.
///
/// 핵심 개념:
/// - @Model: 클래스를 SwiftData가 관리하는 영속 모델로 변환하는 매크로
///   → 내부적으로 PersistentModel 프로토콜 준수를 자동 생성
///   → 프로퍼티 변경을 자동 추적 (observation)
///
/// - struct가 아닌 class를 사용하는 이유:
///   SwiftData는 참조 타입(class)만 지원합니다.
///   → 값 타입(struct)은 identity 개념이 없어 DB 레코드와 매핑 불가
///   → class는 참조로 공유되므로, 한 곳에서 수정하면 모든 곳에서 반영
///
/// - final 키워드: 이 클래스를 상속할 수 없게 합니다.
///   → 상속이 필요 없는 데이터 모델에서 성능 최적화 효과
///   → 컴파일러가 static dispatch를 사용할 수 있음
///
/// 기존 JSON 파일 저장 방식 대비 SwiftData 장점:
/// ┌──────────────────┬────────────────────┬────────────────────┐
/// │      항목        │  JSON (이전)        │  SwiftData (현재)   │
/// ├──────────────────┼────────────────────┼────────────────────┤
/// │ 저장             │ 직접 Encode/Write  │ modelContext.save() │
/// │ 쿼리             │ 전체 로드 후 필터  │ FetchDescriptor     │
/// │ 관계 (1:N)       │ 중첩 JSON          │ @Relationship       │
/// │ 마이그레이션     │ 수동 처리          │ 스키마 버전 관리     │
/// │ 동시성           │ 직접 관리          │ ModelActor 지원     │
/// └──────────────────┴────────────────────┴────────────────────┘
///

import Foundation
import SwiftData

// MARK: - Study Session Model

/// 학습 세션: 타이머 시작~종료까지의 한 번의 학습 기록
///
/// 데이터 흐름:
/// 1. 타이머 시작 → StudySession 생성 (startTime = 현재 시각)
/// 2. 매초마다 → FocusRecord 생성 후 focusRecords에 추가
/// 3. 타이머 종료 → endTime 설정 후 SwiftData에 저장
///
@Model
final class StudySession {
    /// 고유 식별자 (UUID: 전 세계적으로 유일한 128비트 ID)
    var id: UUID

    /// 학습 시작 시각
    var startTime: Date

    /// 학습 종료 시각 (nil이면 아직 진행 중)
    /// Optional(?)인 이유: 타이머가 아직 실행 중이면 종료 시각이 없음
    var endTime: Date?

    /// 📚 @Relationship: SwiftData에서 모델 간 관계를 정의
    ///
    /// deleteRule: .cascade
    ///   → 이 세션이 삭제되면 연결된 모든 FocusRecord도 함께 삭제
    ///   → 다른 옵션: .nullify(관계만 끊기), .deny(자식 있으면 삭제 거부)
    ///
    /// inverse: \FocusRecord.session
    ///   → FocusRecord의 session 프로퍼티가 이 관계의 역방향임을 명시
    ///   → 양방향 관계: Session → Records, Record → Session
    ///
    /// 관계 다이어그램:
    /// StudySession (1) ──── (N) FocusRecord
    ///    parent                    child
    ///    .focusRecords ←──→ .session
    ///
    @Relationship(deleteRule: .cascade, inverse: \FocusRecord.session)
    var focusRecords: [FocusRecord]

    // MARK: - 학습 계획 연동 (스냅샷)

    /// 📚 스냅샷 패턴: 왜 StudyPlan의 ID/제목/색상을 별도로 복사하는가?
    ///
    /// 학습 계획은 나중에 수정/삭제될 수 있습니다.
    /// 만약 @Relationship으로 직접 연결하면:
    ///   - 계획 삭제 시 → 과거 세션의 계획 정보도 사라짐
    ///   - 계획 이름 변경 시 → 과거 기록에도 변경된 이름 표시
    ///
    /// 따라서 세션 생성 시점의 "스냅샷"을 저장합니다:
    ///   session.studyPlanTitle = plan.title  // 값 복사 (참조 아님)
    ///
    /// 이 방식은 회계/주문 시스템에서도 사용합니다:
    ///   - 주문 시점의 "상품명"과 "가격"을 주문 테이블에 복사
    ///   - 나중에 상품 가격이 바뀌어도 주문 기록은 그대로 유지
    ///
    var studyPlanId: UUID?
    var studyPlanTitle: String?
    var studyPlanColorHex: String?

    init(id: UUID = UUID(), startTime: Date = Date()) {
        self.id = id
        self.startTime = startTime
        self.endTime = nil
        self.focusRecords = []
        self.studyPlanId = nil
        self.studyPlanTitle = nil
        self.studyPlanColorHex = nil
    }

    // MARK: - Computed Properties

    /// 📚 Computed Property (계산 프로퍼티):
    /// 저장되지 않고, 접근할 때마다 계산되는 프로퍼티입니다.
    /// SwiftData의 @Model에서 계산 프로퍼티는 DB에 저장되지 않습니다.
    /// → get-only이므로 읽기만 가능 (var이지만 set 불가)

    /// 총 학습 시간 (초 단위, TimeInterval = Double의 별칭)
    var totalDuration: TimeInterval {
        guard let endTime = endTime else {
            // 아직 진행 중이면 현재 시각까지의 시간
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }

    /// 순수 집중 시간 (초)
    /// focusRecords 중 .focused 상태인 것만 필터링하여 duration 합산
    ///
    /// 📚 고차함수 체이닝:
    /// .filter { 조건 }  → 조건에 맞는 요소만 남김
    /// .reduce(초기값) { 누적값, 현재값 in 연산 }  → 하나의 값으로 축소
    ///
    /// 풀어쓰면:
    /// var sum = 0.0               // reduce 초기값
    /// for record in focusRecords {
    ///     if record.focusLevel == .focused {  // filter
    ///         sum += record.duration          // reduce
    ///     }
    /// }
    /// return sum
    ///
    var netFocusTime: TimeInterval {
        focusRecords
            .filter { $0.focusLevel == .focused }
            .reduce(0) { $0 + $1.duration }
        // $0 = 누적값(처음은 0), $1 = 현재 record
    }

    /// 집중률 (%) = 순수 집중 시간 / 총 학습 시간 × 100
    var focusRate: Double {
        guard totalDuration > 0 else { return 0 } // 0으로 나누기 방지
        return (netFocusTime / totalDuration) * 100
    }

    /// 졸음 감지 횟수
    var drowsinessCount: Int {
        focusRecords.filter { $0.focusLevel == .drowsy }.count
    }

    /// 이탈 횟수
    var unfocusedCount: Int {
        focusRecords.filter { $0.focusLevel == .unfocused }.count
    }

    // MARK: - Formatted Strings

    var formattedTotalDuration: String {
        formatDuration(totalDuration)
    }

    var formattedNetFocusTime: String {
        formatDuration(netFocusTime)
    }

    var formattedFocusRate: String {
        String(format: "%.1f%%", focusRate)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d시간 %02d분 %02d초", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d분 %02d초", minutes, seconds)
        } else {
            return String(format: "%d초", seconds)
        }
    }
}

// MARK: - FocusLevel Codable Extension

/// 📚 Extension으로 프로토콜 채택:
/// FocusLevel은 다른 파일에서 정의된 enum입니다.
/// extension으로 Codable을 추가하면 JSON 인코딩/디코딩이 가능해집니다.
/// (레거시 JSON 마이그레이션에 필요)
extension FocusLevel: Codable {}

// MARK: - Hourly Focus Summary (시간대별 집중도 요약)

/// 📚 struct vs class 선택:
/// 이 모델은 SwiftData에 저장하지 않는 일시적 데이터이므로 struct를 사용합니다.
/// - struct: 값 타입, 복사 시 독립적인 복사본 생성, 가벼움
/// - class: 참조 타입, 복사 시 같은 객체를 가리킴, SwiftData 필수
///
struct HourlyFocusSummary: Identifiable {
    let id = UUID()
    let hour: Int  // 0-23
    let averageFocusRate: Double
    let totalRecords: Int

    var hourString: String {
        String(format: "%02d:00", hour)
    }
}
