//
//  FocusState.swift
//  FocusSense
//
//  집중도 상태를 나타내는 모델
//

// ============================================================================
// 📚 [파일 개요] FocusState - 집중도 판단의 핵심 타입들
// ============================================================================
//
// 📚 이 파일에 정의된 타입들:
//
//   1. FocusLevel (enum)     - 집중도 레벨 6단계 (focused ~ unknown)
//   2. HeadPose (struct)     - 머리 방향 (pitch/yaw/roll 각도)
//   3. FocusState (struct)   - 최종 집중 상태 (레벨 + EAR + 얼굴 감지 여부)
//   4. GazeDirection (enum)  - 시선 방향 (center/left/right/up/down)
//   5. EARConstants (struct) - EAR 관련 임계값 상수
//
// 📚 데이터 흐름:
//   SimpleFocusDetectionService가 카메라 프레임을 분석하여
//   FocusState를 생성 → TimerViewModel이 이 값을 받아
//   자동 일시정지 등의 로직을 수행합니다.
//
// 📚 [enum의 rawValue 활용]
//   FocusLevel: String → rawValue가 한국어 문자열 ("집중 중", "졸음" 등)
//   rawValue는 UI에 바로 표시할 수 있는 사용자 친화적 문자열입니다.
//   computed property (icon, color, description)로 각 상태별 UI 정보를 제공합니다.
//
// ============================================================================

import Foundation
import SwiftUI

// MARK: - Focus Level Enum

// 📚 [enum + String + CaseIterable 조합]
//    String: 각 case에 문자열 rawValue 부여 → FocusLevel.focused.rawValue == "집중 중"
//    CaseIterable: .allCases 프로퍼티 자동 생성 → ForEach(FocusLevel.allCases) 사용 가능
enum FocusLevel: String, CaseIterable {
    case focused = "집중 중"
    case warning = "주의"
    case drowsy = "졸음"
    case unfocused = "집중 이탈"
    case away = "자리 비움"
    case unknown = "감지 중"
    
    var icon: String {
        switch self {
        case .focused: return "eye"
        case .warning: return "exclamationmark.triangle"
        case .drowsy: return "moon.zzz"
        case .unfocused: return "eye.slash"
        case .away: return "figure.walk"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .focused: return .green
        case .warning: return .yellow
        case .drowsy: return .red
        case .unfocused: return .orange
        case .away: return .gray
        case .unknown: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .focused: return "집중하고 있어요!"
        case .warning: return "조금 졸리신가요?"
        case .drowsy: return "졸음이 감지되었어요!"
        case .unfocused: return "집중이 필요해요"
        case .away: return "자리를 비우셨네요"
        case .unknown: return "얼굴을 감지 중..."
        }
    }
}

// MARK: - Head Pose

// 📚 [HeadPose - 머리 방향 3축]
//    3D 공간에서 머리의 회전을 3개 축으로 표현합니다:
//    - pitch: 위아래 고개 끄덕임 (고개 숙이면 음수, 들면 양수)
//    - yaw: 좌우 회전 (왼쪽 보면 음수, 오른쪽 보면 양수)
//    - roll: 좌우 기울임 (왼쪽 기울이면 음수, 오른쪽 기울이면 양수)
//    값은 degree(도) 단위입니다.
//
//    Equatable: == 연산자를 자동 생성 (모든 프로퍼티가 Equatable이면 자동)
//    SwiftUI에서 .animation(value:)에 사용하려면 Equatable이 필요합니다.
struct HeadPose: Equatable {
    let pitch: Double  // 위아래 고개
    let yaw: Double    // 좌우 회전
    let roll: Double   // 기울임
    
    init(pitch: Double = 0, yaw: Double = 0, roll: Double = 0) {
        self.pitch = pitch
        self.yaw = yaw
        self.roll = roll
    }
}

// MARK: - Focus State

// 📚 [FocusState - 집중도 분석 최종 결과]
//    SimpleFocusDetectionService가 생성하는 불변(immutable) 데이터입니다.
//    let으로 선언되어 한번 생성하면 변경 불가 → 값의 안전성 보장
//
//    기본값 패턴:
//    init()에서 모든 파라미터에 기본값을 제공하므로
//    FocusState()처럼 빈 생성, FocusState(level: .focused)처럼 부분 생성 가능
struct FocusState: Equatable {
    let level: FocusLevel
    let eyeAspectRatio: Double
    let isLookingAtScreen: Bool
    let isFaceDetected: Bool
    let headPose: HeadPose?
    
    init(
        level: FocusLevel = .unknown,
        eyeAspectRatio: Double = 0,
        isLookingAtScreen: Bool = false,
        isFaceDetected: Bool = false,
        headPose: HeadPose? = nil
    ) {
        self.level = level
        self.eyeAspectRatio = eyeAspectRatio
        self.isLookingAtScreen = isLookingAtScreen
        self.isFaceDetected = isFaceDetected
        self.headPose = headPose
    }
}

// MARK: - Gaze Direction

// 📚 [GazeDirection - 시선 방향]
//    참고: 프로젝트 핵심 원칙에 따르면 시선 방향으로 집중도를 판단하면 안 됩니다!
//    "카메라를 보지 않아도 모니터를 보면 집중" → yaw/pitch로 unfocused 판단 금지
//    이 enum은 디버그 시각화에서만 사용됩니다.
enum GazeDirection: String {
    case center = "정면"
    case left = "왼쪽"
    case right = "오른쪽"
    case up = "위"
    case down = "아래"
    
    var icon: String {
        switch self {
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .center: return "circle.fill"
        }
    }
}

// MARK: - Eye Aspect Ratio Constants

// 📚 [EARConstants - EAR 관련 상수]
//    static let: 인스턴스 생성 없이 EARConstants.drowsinessThreshold로 접근
//    struct에 모아두면 관련 상수를 네임스페이스로 그룹핑할 수 있습니다.
//
//    EAR(Eye Aspect Ratio) = 눈의 세로/가로 비율
//    정상: ~0.3 | 졸음: < 0.2
//    consecutiveFramesForDrowsiness: 1FPS 기준 15프레임 = 15초 연속이면 졸음
struct EARConstants {
    static let drowsinessThreshold: Double = 0.2  // 이 값 이하면 졸음
    static let blinkThreshold: Double = 0.25      // 깜빡임 감지 임계값
    static let consecutiveFramesForDrowsiness: Int = 15  // 연속 프레임 수
}
