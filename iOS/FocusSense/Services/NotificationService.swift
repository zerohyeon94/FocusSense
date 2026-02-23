//
//  NotificationService.swift
//  FocusSense
//
//  로컬 알림 관리 서비스
//

// ============================================================================
// 📚 파일 개요: NotificationService
// ============================================================================
// 이 파일은 iOS 로컬 알림(Local Notification)을 관리하는 서비스입니다.
//
// 📚 로컬 알림 vs 푸시 알림:
//   - 로컬 알림: 앱 자체에서 예약 → 서버 없이 동작 → 이 파일이 사용하는 방식
//   - 푸시 알림: 외부 서버(APNs)에서 보냄 → 서버 인프라 필요
//   둘 다 사용자에게는 동일하게 보임 (배너, 소리, 뱃지)
//
// 📚 앱이 꺼져도 알림이 오는 원리 (중요!):
//   iOS에서 UNUserNotificationCenter.add()로 알림을 등록하면,
//   해당 정보는 iOS 시스템 레벨(SpringBoard)에 전달됨.
//   즉, 알림 스케줄은 앱이 아닌 "iOS 운영체제"가 관리함.
//   따라서 앱이 종료되어도, 백그라운드에 없어도, 지정된 시간에 iOS가 알림을 띄워줌.
//   (단, 사용자가 설정에서 알림을 끄면 표시되지 않음)
//
// 📚 핵심 클래스 관계:
//   UNUserNotificationCenter (시스템 싱글톤)
//       ↑ add(request)    — 알림 등록
//       ↑ removePending... — 알림 제거
//       ↑ delegate         — 알림 수신 시 콜백
//       |
//   NotificationService (우리의 래퍼)
//       → 비즈니스 로직에 맞게 알림을 관리하는 편의 계층
//
// 📚 아키텍처에서의 위치:
//   StudyPlanStore → NotificationService → UNUserNotificationCenter (iOS 시스템)
// ============================================================================

import Foundation
import UserNotifications

// MARK: - Notification Service

// 📚 NSObject 상속 + UNUserNotificationCenterDelegate 채택
//
// 1. NSObject를 상속하는 이유:
//    UNUserNotificationCenterDelegate는 Objective-C 기반 프로토콜.
//    Objective-C 프로토콜을 채택하려면 반드시 NSObject를 상속해야 함.
//    (순수 Swift 클래스는 Objective-C 런타임 기능이 없어서 delegate로 등록 불가)
//
// 2. UNUserNotificationCenterDelegate 프로토콜:
//    iOS 알림 시스템이 "이벤트가 발생했을 때 누구에게 알려줄지"를 정하는 인터페이스.
//    이 프로토콜을 채택하면 두 가지 콜백을 받을 수 있음:
//      - willPresent: 앱이 포그라운드일 때 알림이 도착하면 호출
//      - didReceive: 사용자가 알림을 탭하면 호출
//
// 📚 Delegate 패턴이란?
//    "내가 직접 하지 않고, 다른 객체에게 위임(delegate)하는 패턴"
//    iOS 알림 시스템은 알림이 도착했을 때 어떻게 처리할지 모름.
//    → NotificationService를 delegate로 지정하면,
//      알림 도착 시 "너에게 위임할게, 어떻게 할지 결정해"라고 콜백을 보냄.
//    → 우리가 willPresent에서 [.banner, .sound, .badge]를 반환하면,
//      시스템이 "알겠어, 배너+소리+뱃지로 표시할게"라고 처리.
//
// 📚 왜 @MainActor가 없는가?
//    Store들과 달리 @Published 프로퍼티가 없고, UI를 직접 업데이트하지 않음.
//    알림 등록/제거는 UNUserNotificationCenter가 내부적으로 스레드 안전하게 처리.
//    → @MainActor 불필요. 오히려 메인 스레드를 점유하지 않아 성능에 유리.
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    // 📚 UNUserNotificationCenter.current() — 싱글톤 패턴
    // iOS 알림 시스템은 앱당 하나의 UNUserNotificationCenter만 존재.
    // .current()로 그 유일한 인스턴스를 가져옴.
    // private let으로 저장해서 매번 .current()를 호출하지 않아도 됨.
    private let center = UNUserNotificationCenter.current()

    // 📚 override init() — NSObject의 init()을 재정의
    // super.init()을 먼저 호출한 후, delegate를 설정.
    // 이 순서가 중요: super.init() 전에는 self를 사용할 수 없음 (Swift 안전 규칙)
    override init() {
        super.init()
        // 📚 center.delegate = self
        // "알림 관련 이벤트가 발생하면, 나(NotificationService)에게 알려달라"
        // 이 한 줄이 Delegate 패턴의 핵심: 위임 대상을 연결하는 것.
        // 이 설정이 없으면 willPresent, didReceive 메서드가 절대 호출되지 않음.
        //
        // 📚 포그라운드에서도 알림을 표시하려면 delegate 설정이 필수!
        // iOS 기본 동작: 앱이 포그라운드일 때 알림을 표시하지 않음.
        // delegate를 설정하고 willPresent에서 표시 옵션을 반환해야 포그라운드 알림 가능.
        // delegate 설정 — 포그라운드에서도 알림 표시
        center.delegate = self
    }

    // MARK: - UNUserNotificationCenterDelegate

    // 📚 이 메서드는 "앱이 화면에 보이는 상태(포그라운드)"에서 알림이 도착하면 호출됨.
    // iOS 기본 동작: 포그라운드에서는 알림 배너를 표시하지 않음.
    // completionHandler에 표시 옵션을 전달하면 포그라운드에서도 알림이 보임:
    //   - .banner: 화면 상단 배너
    //   - .sound: 알림 소리
    //   - .badge: 앱 아이콘의 뱃지 숫자
    //
    // 📚 completionHandler 패턴 (콜백):
    // iOS 시스템이 "표시 옵션을 결정했으면 이 함수를 호출해줘"라고 전달하는 클로저.
    // 반드시 호출해야 함! 호출하지 않으면 시스템이 무한 대기 상태에 빠질 수 있음.
    // @escaping: 이 클로저가 메서드 실행 이후에도 살아있을 수 있다는 의미.

    /// 앱이 포그라운드일 때도 알림 배너 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // 📚 이 메서드는 "사용자가 알림을 탭했을 때" 호출됨.
    // response.notification.request.identifier로 어떤 알림인지 식별 가능.
    // 여기서 특정 화면으로 이동하는 딥링크 처리 등을 할 수 있음.
    // 현재는 로그만 출력하지만, 추후 "해당 학습 계획 화면으로 이동" 등 확장 가능.

    /// 사용자가 알림을 탭했을 때 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📲 알림 탭: \(response.notification.request.identifier)")
        completionHandler()
    }

    // MARK: - Permission

    // 📚 @discardableResult란?
    // 이 함수는 Bool을 반환하지만, 반환값을 사용하지 않아도 컴파일러 경고가 나지 않음.
    // 사용 시나리오:
    //   1. 반환값 사용: let granted = await requestPermission() → 결과에 따라 분기
    //   2. 반환값 무시: await requestPermission() → 단순히 권한 요청만 하고 결과 무시
    // @discardableResult가 없으면, 반환값을 무시할 때마다 "_ =" 를 붙여야 하는 불편함
    //
    // 📚 async/await 비동기 패턴
    // requestAuthorization()은 사용자에게 권한 팝업을 보여주는 비동기 작업.
    // 팝업이 떠서 사용자가 "허용/거부"를 누를 때까지 기다려야 하므로 async.
    //   - async: "이 함수는 중간에 기다리는 지점이 있어요"
    //   - await: "여기서 결과가 올 때까지 기다릴게요" (하지만 스레드는 블록하지 않음!)
    //
    // 📚 try await — async + throws 조합
    // requestAuthorization()은 async이면서 throws이기도 함.
    // → 네트워크 오류 등으로 실패할 수 있으므로, do-catch로 에러 처리 필요

    /// 알림 권한 요청
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ 알림 권한 허용")
            } else {
                print("⚠️ 알림 권한 거부")
            }
            return granted
        } catch {
            print("❌ 알림 권한 요청 실패: \(error)")
            return false
        }
    }

    // 📚 async이지만 throws가 아닌 경우
    // notificationSettings()는 실패하지 않는 비동기 작업.
    // iOS 시스템에서 현재 설정을 조회하기만 하므로, 에러가 발생할 이유가 없음.
    // → do-catch 없이 await만 사용

    /// 현재 알림 권한 상태 확인
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    /// 학습 계획에 대한 알림 등록 (권한 확인 후 등록)
    func scheduleNotifications(for plan: StudyPlan) async {
        guard plan.isReminderEnabled && plan.isActive else { return }

        // 📚 권한 확인을 매번 하는 이유:
        // 사용자가 설정 앱에서 언제든 알림 권한을 끌 수 있음.
        // 이전에 권한을 허용했어도, 지금은 거부 상태일 수 있음.
        // → 알림 등록 전에 항상 현재 상태를 확인하는 것이 안전한 패턴
        //
        // 📚 .provisional (임시 권한):
        // iOS 12+에서 도입. 사용자에게 명시적 허용을 묻지 않고 "조용한 알림"을 보낼 수 있는 상태.
        // 알림 센터에만 표시되고 배너/소리는 없음. 사용자가 나중에 정식 허용/거부를 결정.

        // 권한 확인
        let status = await checkPermissionStatus()
        guard status == .authorized || status == .provisional else {
            print("⚠️ 알림 권한이 없어 알림을 등록하지 않습니다")
            return
        }

        // 📚 switch 문으로 열거형(enum)을 분기하는 패턴
        // Swift의 switch는 exhaustive(완전)해야 함 → 모든 case를 처리해야 컴파일됨.
        // 이 특성 덕분에, 나중에 recurrenceType에 새 case를 추가하면
        // 컴파일러가 "여기도 처리해야 해!"라고 알려줌. → 실수를 방지하는 타입 안전성.
        switch plan.recurrenceType {
        case .daily:
            // 매일 알림: 모든 요일에 등록
            for weekday in 1...7 {
                scheduleWeekdayNotification(for: plan, weekday: weekday)
            }

        case .weekdays(let days):
            // 📚 연관 값(Associated Value) 패턴: .weekdays(let days)
            // enum case에 데이터를 담는 Swift의 강력한 기능.
            // .weekdays([1, 3, 5]) → "월, 수, 금"에 해당하는 요일 배열을 꺼냄.
            // let days로 바인딩하면 해당 배열을 바로 사용 가능.

            // 특정 요일만 알림
            for weekday in days {
                scheduleWeekdayNotification(for: plan, weekday: weekday)
            }
        }

        print("✅ 알림 등록 완료: \(plan.title)")
    }

    /// 특정 요일에 대한 알림 등록
    private func scheduleWeekdayNotification(for plan: StudyPlan, weekday: Int) {
        // 📚 UNMutableNotificationContent — 알림의 "내용"을 담는 객체
        // Mutable(변경 가능)인 이유: 생성 후 프로퍼티를 하나씩 설정해야 하므로
        let content = UNMutableNotificationContent()
        content.title = "학습 시간"
        content.body = "\(plan.title) 학습을 시작할 시간입니다!"
        content.sound = .default

        // 📚 DateComponents — 날짜/시간의 "부분"을 표현하는 구조체
        // 전체 날짜(Date)가 아닌, 필요한 구성요소만 지정.
        // weekday: 1=일, 2=월, ..., 7=토 (Apple 표준)
        // hour, minute: 시/분 (24시간제)
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = plan.reminderHour
        dateComponents.minute = plan.reminderMinute

        // 📚 UNCalendarNotificationTrigger — 달력 기반 알림 트리거
        // dateMatching: 지정된 DateComponents와 일치하는 시점에 발동
        // repeats: true → 매주 같은 요일/시간에 반복!
        //
        // 📚 repeats: true의 동작 원리 (중요!):
        //   repeats: false → 한 번만 알림 후 자동 삭제
        //   repeats: true  → iOS 시스템이 매주 해당 요일/시간에 반복 알림
        //   → 앱이 꺼져 있어도 iOS 시스템 레벨에서 반복 실행됨!
        //   → 알림을 중지하려면 명시적으로 removeNotifications()를 호출해야 함
        //
        // 📚 다른 트리거 종류:
        //   - UNTimeIntervalNotificationTrigger: N초 후 발동 (타이머)
        //   - UNLocationNotificationTrigger: 특정 위치에 도착/출발 시 발동
        //   - UNCalendarNotificationTrigger: 특정 날짜/시간에 발동 (이 코드에서 사용)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        // 📚 알림 식별자(identifier)의 중요성:
        // 각 알림은 고유한 문자열 ID를 가짐.
        // 같은 ID로 새 알림을 등록하면, 기존 알림이 자동으로 덮어씌워짐 (중복 방지).
        // 삭제할 때도 이 ID로 특정 알림만 골라서 제거할 수 있음.
        // 형식: "studyplan-{planId}-{weekday}" → 계획별, 요일별로 고유하게 식별
        let identifier = notificationIdentifier(planId: plan.id, weekday: weekday)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // 📚 center.add()는 completion handler 방식 (콜백 기반)
        // 이 메서드는 async 버전이 아닌 클로저 기반 API.
        // 알림 등록은 iOS 시스템에 전달하고 결과를 콜백으로 받음.
        // error가 nil이면 성공, 아니면 실패.
        center.add(request) { error in
            if let error {
                print("❌ 알림 등록 실패 (\(identifier)): \(error)")
            }
        }
    }

    // MARK: - Remove Notifications

    /// 특정 학습 계획의 모든 알림 제거
    func removeNotifications(for planId: UUID) {
        // 📚 (1...7).map { } — 범위(Range)에 map 적용
        // 1~7(일~토) 모든 요일에 대한 알림 ID를 한 번에 생성.
        // 해당 계획이 실제로 모든 요일에 알림을 등록하지 않았더라도,
        // 존재하지 않는 ID를 삭제 시도해도 에러가 발생하지 않으므로 안전.
        // → "일부 요일만 확인"보다 "전체 요일 삭제"가 코드가 단순하고 안전
        let identifiers = (1...7).map { notificationIdentifier(planId: planId, weekday: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("✅ 알림 제거: \(planId.uuidString.prefix(8))")
    }

    // 📚 전체 재등록(Refresh) 패턴
    // "기존 알림 모두 제거 → 필요한 것만 다시 등록"
    // 개별 알림을 하나씩 비교하며 업데이트하는 것보다
    // 전체를 리셋하고 다시 등록하는 것이 더 단순하고 안전함.
    // 약간의 성능 비용이 있지만, 알림 수가 적으므로(수십 개 이하) 문제없음.

    /// 모든 학습 계획의 알림 전체 재등록
    func refreshAllNotifications(plans: [StudyPlan]) async {
        // 기존 알림 모두 제거
        center.removeAllPendingNotificationRequests()

        // 📚 for ... where — 조건부 반복문
        // for plan in plans where plan.isReminderEnabled && plan.isActive
        // → plans 배열에서 조건을 만족하는 항목만 반복
        // filter + for 를 합쳐놓은 간결한 문법
        // where 절 덕분에 내부에 if문 없이도 필터링 가능

        // 활성 계획의 알림 재등록
        for plan in plans where plan.isReminderEnabled && plan.isActive {
            await scheduleNotifications(for: plan)
        }

        let count = plans.filter { $0.isReminderEnabled && $0.isActive }.count
        print("🔄 전체 알림 갱신: \(count)개")
    }

    // MARK: - Debug

    // 📚 디버깅 전용 메서드
    // 개발 중에 "지금 등록된 알림이 뭐가 있지?"를 확인할 때 유용.
    // 출시 후에는 사용하지 않지만, 삭제하지 않고 남겨두면 디버깅 시 편리.
    // pendingNotificationRequests()는 async → 시스템에서 정보를 조회하는 데 시간이 걸림

    /// 등록된 대기 중 알림 목록 출력
    func printPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        print("📋 대기 중 알림: \(requests.count)개")
        for request in requests {
            // 📚 as? — 안전한 타입 캐스팅(Optional Downcasting)
            // trigger는 UNNotificationTrigger 타입이지만,
            // 우리는 UNCalendarNotificationTrigger의 dateComponents에 접근하고 싶음.
            // as?로 캐스팅하면: 성공 시 해당 타입, 실패 시 nil
            // → if let과 조합하면 안전하게 타입을 확인하고 사용 가능
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("  - \(request.identifier): \(trigger.dateComponents)")
            }
        }
    }

    // MARK: - Helpers

    // 📚 식별자 생성을 별도 메서드로 분리하는 이유:
    // 알림 등록(schedule)과 제거(remove) 모두 동일한 형식의 ID를 사용해야 함.
    // 형식이 한곳에서 관리되므로, 수정 시 한 군데만 바꾸면 됨 (DRY 원칙).
    // 형식: "studyplan-{UUID}-{요일번호}"

    /// 알림 식별자 생성
    private func notificationIdentifier(planId: UUID, weekday: Int) -> String {
        "studyplan-\(planId.uuidString)-\(weekday)"
    }
}
