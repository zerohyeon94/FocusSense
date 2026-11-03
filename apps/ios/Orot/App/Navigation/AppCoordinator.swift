//
//  AppCoordinator.swift
//  FocusSense
//
//  MVVM-C 패턴의 Coordinator
//  화면 전환 로직을 ViewModel에서 분리
//

// =============================================================================
// 📚 파일 개요: AppCoordinator.swift
// =============================================================================
// 이 파일은 **MVVM-C(Coordinator) 패턴**의 Coordinator 역할을 합니다.
//
// 📚 MVVM-C 패턴이란?
//   MVVM(Model-View-ViewModel)에 Coordinator(C)를 추가한 아키텍처 패턴입니다.
//   - Model: 데이터와 비즈니스 로직
//   - View: UI 표시 (SwiftUI View)
//   - ViewModel: View와 Model 사이의 로직 처리
//   - Coordinator: **화면 전환(네비게이션) 로직을 중앙에서 관리**
//
// 📚 왜 Coordinator가 필요한가?
//   화면 전환 로직이 각 View나 ViewModel에 흩어지면:
//   1. View 간 결합도가 높아짐 (View A가 View B를 직접 알아야 함)
//   2. 화면 전환 흐름을 파악하기 어려움
//   3. 테스트가 어려움 (UI 없이 네비게이션 로직 테스트 불가)
//
//   Coordinator로 분리하면:
//   1. 화면 전환 로직이 한 곳에 모임 → 흐름 파악 쉬움
//   2. View는 "무엇을 보여줄지"만 책임 → 단일 책임 원칙
//   3. 테스트 용이 → Coordinator만 테스트하면 네비게이션 검증 가능
//
// 📚 핵심 개념:
//   1. @MainActor: UI 업데이트를 보장하는 동시성 제어
//   2. ObservableObject + @Published: 상태 변경 시 View 자동 업데이트
//   3. NavigationPath: 프로그래밍 방식의 네비게이션 스택 관리
//   4. enum + Identifiable: 타입 안전한 Sheet/Alert 관리
// =============================================================================

import SwiftUI
import Combine

// MARK: - Navigation Destination

// 📚 enum + Hashable: 네비게이션 목적지를 열거형으로 정의합니다.
//    Hashable 채택이 필요한 이유: NavigationPath가 내부적으로
//    값을 해시하여 네비게이션 스택을 관리하기 때문입니다.
//    연관값(associated value)이 있는 case(sessionDetail)도
//    연관값 타입이 Hashable이면 자동으로 Hashable을 합성합니다.
enum AppDestination: Hashable {
    case timer
    case analytics
    case settings
    case sessionDetail(sessionId: UUID) // 📚 연관값(Associated Value): enum case에 데이터를 함께 저장
}

// MARK: - App Coordinator

// 📚 @MainActor: 이 클래스의 모든 프로퍼티와 메서드가 메인 스레드에서 실행됨을 보장합니다.
//    UI 업데이트는 반드시 메인 스레드에서 이루어져야 하므로,
//    네비게이션 상태를 변경하는 Coordinator에 적용합니다.
//    Swift Concurrency 환경에서 데이터 레이스(Data Race)를 방지합니다.
@MainActor
// 📚 final class: 상속을 금지하는 클래스입니다.
//    final을 붙이면:
//    1. 이 클래스를 상속받는 서브클래스를 만들 수 없음
//    2. 컴파일러가 메서드를 직접 호출(Static Dispatch)하여 성능이 향상됨
//    3. "이 클래스는 완결된 설계이다"라는 의도를 명확히 전달
// 📚 ObservableObject: SwiftUI에서 객체의 상태 변화를 관찰할 수 있게 하는 프로토콜입니다.
//    @Published 프로퍼티가 변경되면 이 객체를 구독하는 모든 View가 자동으로 다시 그려집니다.
final class AppCoordinator: ObservableObject {

    // MARK: - Published Properties

    // 📚 @Published: 이 프로퍼티가 변경될 때마다 ObservableObject의 objectWillChange를
    //    자동으로 발생시킵니다. SwiftUI View가 이 변경을 감지하고 화면을 업데이트합니다.

    // 📚 NavigationPath: iOS 16+에서 도입된 타입으로, 네비게이션 스택을 프로그래밍 방식으로
    //    관리합니다. 배열처럼 append/removeLast로 화면을 push/pop할 수 있습니다.
    //    기존 NavigationLink만으로는 복잡한 네비게이션 흐름을 제어하기 어려웠는데,
    //    NavigationPath가 이 문제를 해결합니다.
    @Published var path = NavigationPath()
    @Published var selectedTab: Int = 0
    @Published var showingSheet: SheetType?
    @Published var showingAlert: AlertType?

    // MARK: - Sheet Types

    // 📚 enum + Identifiable: Sheet/Alert를 타입 안전하게 관리하는 패턴입니다.
    //    SwiftUI의 .sheet(item:) 수정자는 Identifiable을 채택한 타입을 받습니다.
    //    왜 Identifiable이 필요한가?
    //    - SwiftUI가 "어떤 시트가 표시 중인지" 고유하게 식별해야 하기 때문입니다.
    //    - 같은 타입의 시트가 여러 개일 때 혼동을 방지합니다.
    //    각 case마다 고유한 id를 반환하여 SwiftUI가 구분할 수 있게 합니다.
    enum SheetType: Identifiable {
        case sessionSummary(StudySession)
        case cameraPermission

        // 📚 computed property로 id를 구현하여 Identifiable 프로토콜을 충족합니다.
        //    각 case마다 고유한 문자열을 반환합니다.
        var id: String {
            switch self {
            case .sessionSummary: return "sessionSummary"
            case .cameraPermission: return "cameraPermission"
            }
        }
    }

    // MARK: - Alert Types

    // 📚 AlertType도 SheetType과 동일한 패턴입니다.
    //    연관값 cameraError(String)으로 에러 메시지를 전달할 수 있어
    //    다양한 에러 상황에 대응 가능합니다.
    enum AlertType: Identifiable {
        case resetConfirmation
        case thermalWarning
        case cameraError(String)

        var id: String {
            switch self {
            case .resetConfirmation: return "resetConfirmation"
            case .thermalWarning: return "thermalWarning"
            case .cameraError: return "cameraError"
            }
        }
    }

    // MARK: - Navigation Methods

    // 📚 네비게이션 메서드 패턴:
    //    Coordinator가 네비게이션 로직을 캡슐화합니다.
    //    View에서 직접 path를 조작하는 대신, coordinator.navigate(to:)를 호출합니다.
    //    이렇게 하면 네비게이션 로직이 변경되어도 View 코드를 수정할 필요가 없습니다.
    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func navigateBack() {
        // 📚 guard문으로 빈 스택에서 pop하는 런타임 에러를 방지합니다.
        //    방어적 프로그래밍(Defensive Programming)의 좋은 예시입니다.
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // 📚 navigateToRoot: 네비게이션 스택의 모든 항목을 제거하여 루트 화면으로 돌아갑니다.
    //    path.count만큼 removeLast하면 스택이 완전히 비워집니다.
    func navigateToRoot() {
        path.removeLast(path.count)
    }

    // MARK: - Tab Navigation

    // 📚 탭 전환 메서드: selectedTab 값을 변경하면 @Published에 의해
    //    TabView(selection:)이 자동으로 해당 탭으로 전환됩니다.
    //    숫자 대신 명명된 메서드(showHome, showTimer 등)를 사용하면
    //    코드 가독성이 높아지고, 탭 순서가 변경되어도 한 곳만 수정하면 됩니다.
    func switchToTab(_ tab: Int) {
        selectedTab = tab
    }

    func showHome() {
        switchToTab(0)
    }

    func showTimer() {
        switchToTab(1)
    }

    func showAnalytics() {
        switchToTab(2)
    }

    func showSettings() {
        switchToTab(3)
    }

    // MARK: - Sheet Methods

    // 📚 Sheet 표시 패턴:
    //    showingSheet에 값을 할당하면 SwiftUI의 .sheet(item:) 수정자가
    //    자동으로 시트를 표시합니다. nil을 할당하면 시트가 닫힙니다.
    //    Optional + Identifiable을 활용한 선언적(Declarative) UI 패턴입니다.
    func presentSessionSummary(_ session: StudySession) {
        showingSheet = .sessionSummary(session)
    }

    func presentCameraPermission() {
        showingSheet = .cameraPermission
    }

    func dismissSheet() {
        showingSheet = nil
    }

    // MARK: - Alert Methods

    // 📚 Alert도 Sheet와 동일한 패턴으로 관리됩니다.
    //    showingAlert에 값을 할당 → Alert 표시, nil 할당 → Alert 닫기.
    //    이 일관된 패턴 덕분에 코드 예측성이 높아집니다.
    func showResetConfirmation() {
        showingAlert = .resetConfirmation
    }

    func showThermalWarning() {
        showingAlert = .thermalWarning
    }

    func showCameraError(_ message: String) {
        showingAlert = .cameraError(message)
    }

    func dismissAlert() {
        showingAlert = nil
    }
}
