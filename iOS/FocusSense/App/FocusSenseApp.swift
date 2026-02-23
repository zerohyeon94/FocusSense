//
//  FocusSenseApp.swift
//  FocusSense
//
//  AI-Powered Focus Tracking Study Timer
//

// =============================================================================
// 📚 파일 개요: FocusSenseApp.swift
// =============================================================================
// 이 파일은 앱의 **진입점(Entry Point)** 입니다.
//
// 📚 SwiftUI 앱의 생명주기:
//   @main → FocusSenseApp(App 프로토콜) → body → Scene → WindowGroup → View
//
// 📚 핵심 개념:
//   1. @main: 프로그램의 시작점을 지정하는 Swift 속성
//   2. App 프로토콜: SwiftUI 앱의 구조와 동작을 정의하는 프로토콜
//   3. Scene: 앱의 UI 계층 구조를 담는 컨테이너 (WindowGroup, DocumentGroup 등)
//   4. WindowGroup: 가장 일반적인 Scene으로, 하나의 윈도우를 관리
//   5. ModelContainer: SwiftData의 데이터 저장소를 설정하고 관리
//   6. ZStack + 스플래시: 메인 화면 위에 스플래시를 겹쳐서 앱 로딩 효과 구현
// =============================================================================

/// 해당 파일의 중점
/// 앱 실행 흐름:
/// @main → FocusSenseApp → body → WindowGroup → ContentView()

import SwiftUI
import SwiftData
import UserNotifications

// 📚 @main: Swift 5.3부터 도입된 속성으로, 앱의 진입점을 표시합니다.
//    전통적인 UIKit의 AppDelegate + main.swift 역할을 이 한 줄로 대체합니다.
//    프로젝트 전체에서 단 하나의 @main만 존재해야 합니다.
@main // 앱의 시작지점
// 📚 App 프로토콜: SwiftUI에서 앱 자체를 정의하는 프로토콜입니다.
//    UIKit의 UIApplicationDelegate를 대체하며, body 프로퍼티에서 Scene을 반환합니다.
//    struct로 선언하여 값 타입이지만, 실제 앱 인스턴스는 시스템이 관리합니다.
struct FocusSenseApp: App {

    // 📚 @StateObject: SwiftUI에서 ObservableObject를 "생성하고 소유"할 때 사용합니다.
    //    앱의 최상위 레벨에서 생성하므로, 앱이 살아있는 동안 이 객체도 유지됩니다.
    //    자식 View에서 같은 객체를 참조할 때는 @ObservedObject나 @EnvironmentObject를 씁니다.
    // @StateObject: 객체를 생성하고 소유함
    @StateObject private var appCoordinator = AppCoordinator()

    // 📚 @State: View(또는 App)가 소유하는 단순 값 타입 상태입니다.
    //    값이 변경되면 SwiftUI가 자동으로 화면을 다시 그립니다(re-render).
    //    private으로 선언하여 이 범위 내에서만 직접 수정 가능합니다.
    // 스플래시 표시 상태
    @State private var showSplash = true

    // 📚 ModelContainer: SwiftData의 핵심 컴포넌트로, 데이터베이스를 설정합니다.
    //    CoreData의 NSPersistentContainer에 해당하며, Schema(모델 정의)와
    //    ModelConfiguration(저장 옵션)을 받아서 초기화합니다.
    //    let으로 선언한 이유: 한 번 설정된 컨테이너는 변경할 필요가 없기 때문입니다.
    // SwiftData ModelContainer
    let modelContainer: ModelContainer

    // 📚 App의 init(): 앱이 시작될 때 한 번만 호출됩니다.
    //    여기서 SwiftData 설정, 전역 서비스 초기화 등을 수행합니다.
    //    주의: init()에서 @State, @StateObject 등은 직접 접근할 수 없으므로,
    //    이러한 상태의 초기화는 .task나 .onAppear에서 처리합니다.
    init() {
        do {
            // 📚 Schema: SwiftData에 저장할 모델 타입들을 등록합니다.
            //    @Model 매크로가 붙은 클래스들만 등록 가능합니다.
            let schema = Schema([
                StudySession.self,
                FocusRecord.self,
                StudyPlan.self
            ])
            // 📚 ModelConfiguration: 데이터베이스의 저장 방식을 설정합니다.
            //    기본적으로 앱의 Application Support 디렉토리에 SQLite 파일로 저장됩니다.
            //    isStoredInMemoryOnly: true로 하면 메모리에만 저장 (테스트용).
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // 📚 fatalError: 앱이 복구 불가능한 상태일 때 즉시 종료합니다.
            //    ModelContainer 초기화 실패는 앱이 동작할 수 없는 상태이므로
            //    fatalError로 처리하는 것이 적절합니다.
            fatalError("❌ ModelContainer 초기화 실패: \(error)")
        }
    }

    // 📚 body: App 프로토콜의 필수 프로퍼티입니다.
    //    some Scene을 반환하여 앱이 어떤 화면 구조를 가질지 정의합니다.
    //    View의 body와 유사하지만, View 대신 Scene을 반환합니다.
    // body: 앱의 화면 구성 정의
    var body: some Scene {
        // 📚 WindowGroup: iOS에서 가장 일반적인 Scene 타입입니다.
        //    하나의 메인 윈도우를 생성하며, iPadOS에서는 멀티 윈도우도 지원합니다.
        //    macOS에서는 여러 윈도우를 생성할 수 있는 메뉴 항목이 자동으로 추가됩니다.
        WindowGroup { // 앱의 메인 윈도우
            // 📚 ZStack: 뷰를 Z축(깊이 방향)으로 겹쳐 쌓는 컨테이너입니다.
            //    여기서는 ContentView 위에 SplashView를 오버레이하는 데 사용합니다.
            //    가장 먼저 선언된 뷰가 맨 아래, 마지막이 맨 위에 위치합니다.
            ZStack {
                ContentView()
                    // 📚 .environmentObject(): 환경 객체를 하위 뷰 트리 전체에 주입합니다.
                    //    appCoordinator를 여기서 주입하면, 모든 하위 뷰에서
                    //    @EnvironmentObject로 접근할 수 있습니다.
                    //    의존성 주입(DI)의 SwiftUI 버전이라고 볼 수 있습니다.
                    .environmentObject(appCoordinator)
                    // 📚 .preferredColorScheme(.dark): 앱 전체를 다크 모드로 고정합니다.
                    //    이 설정은 시스템 설정에 관계없이 항상 다크 모드를 사용합니다.
                    .preferredColorScheme(.dark)

                // 📚 스플래시 오버레이 패턴:
                //    조건부 렌더링(if showSplash)으로 스플래시를 표시/숨김 처리합니다.
                //    .transition(.opacity)와 함께 withAnimation을 사용하면
                //    뷰가 사라질 때 페이드아웃 애니메이션이 적용됩니다.
                //    .zIndex(1)로 반드시 ContentView 위에 표시되도록 보장합니다.
                // 스플래시 오버레이
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            // 📚 .task: iOS 15+에서 사용 가능한 비동기 수정자입니다.
            //    뷰가 나타날 때 비동기(async) 코드를 실행할 수 있습니다.
            //    .onAppear와 다른 점:
            //    - async/await 사용 가능
            //    - 뷰가 사라지면 자동으로 Task가 취소됨 (메모리 누수 방지)
            //    - 구조화된 동시성(Structured Concurrency)을 따름
            .task {
                // 앱 시작 시 알림 권한 상태 확인
                await requestNotificationPermissionIfNeeded()

                // 📚 Task.sleep: 비동기적으로 일정 시간 대기합니다.
                //    Thread.sleep과 달리 스레드를 차단하지 않습니다.
                //    try?로 감싸서 취소 시 에러를 무시합니다.
                try? await Task.sleep(for: .seconds(1.8))
                // 📚 withAnimation: 클로저 내의 상태 변경을 애니메이션으로 처리합니다.
                //    .easeOut: 끝부분이 느려지는 애니메이션 커브
                //    showSplash가 false로 바뀌면 SplashView가 .transition(.opacity)에 의해
                //    페이드아웃되면서 사라집니다.
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
        // 📚 .modelContainer(): Scene 수정자로, SwiftData의 ModelContainer를 주입합니다.
        //    이렇게 하면 하위의 모든 View에서 @Environment(\.modelContext)로
        //    ModelContext에 접근할 수 있습니다.
        //    앱 전체에서 동일한 데이터베이스를 공유하는 핵심 설정입니다.
        .modelContainer(modelContainer)
    }

    // MARK: - Notification Permission

    /// 앱 시작 시 알림 권한 확인 (이미 학습 계획에 알림이 설정되어 있으면 권한 요청)
    // 📚 async 함수: Swift Concurrency를 사용한 비동기 함수입니다.
    //    UNUserNotificationCenter의 API가 async이므로 이 함수도 async로 선언했습니다.
    //    private: 이 struct 내부에서만 사용하는 헬퍼 함수이므로 접근 제한합니다.
    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        // 📚 await: 비동기 작업이 완료될 때까지 기다립니다.
        //    notificationSettings()는 시스템에 현재 알림 설정을 조회하는 비동기 함수입니다.
        let settings = await center.notificationSettings()

        // 📚 switch + enum: Swift의 패턴 매칭으로 모든 권한 상태를 처리합니다.
        //    @unknown default: 미래에 추가될 수 있는 새로운 case를 안전하게 처리합니다.
        //    이렇게 하면 새 OS 버전에서 case가 추가되어도 컴파일 경고가 발생합니다.
        switch settings.authorizationStatus {
        case .notDetermined:
            // 아직 권한을 요청하지 않은 경우, 알림 계획이 있을 때만 요청
            // (configure 전이므로 pending requests로 확인)
            let pendingRequests = await center.pendingNotificationRequests()
            if !pendingRequests.isEmpty {
                _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            }
        case .denied:
            print("⚠️ 알림 권한이 거부되어 있습니다. 설정에서 변경해주세요.")
        case .authorized, .provisional, .ephemeral:
            print("✅ 알림 권한 확인됨")
        @unknown default:
            break
        }
    }
}
