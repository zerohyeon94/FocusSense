//
//  FocusDetectionServiceProtocol.swift
//  FocusSense
//
//  Vision / CoreML 서비스의 공통 인터페이스
//

// ============================================================================
// 📚 [파일 개요] FocusDetectionServiceProtocol - 집중도 감지 서비스 공통 인터페이스
// ============================================================================
//
// 📌 Protocol (프로토콜)이란?
//    Swift의 Protocol은 Java/Kotlin의 Interface와 같은 개념입니다.
//    "이 기능을 가져야 한다"는 **계약(contract)**을 정의하며,
//    실제 구현은 각 클래스가 자유롭게 결정합니다.
//
// 📌 ObservableObject 프로토콜 요구
//    이 프로토콜은 ObservableObject를 상속하므로,
//    이를 채택하는 클래스는 @Published 프로퍼티 변경 시
//    SwiftUI View가 자동으로 UI를 갱신할 수 있습니다.
//
// 📌 의존성 주입(Dependency Injection)과 테스트 용이성
//    ViewModel이 구체 클래스가 아닌 프로토콜에 의존하면:
//    - 런타임에 다른 구현체로 교체 가능 (전략 패턴)
//    - 테스트 시 Mock 객체를 주입하여 단위 테스트 가능
//    - 서비스 간 결합도(coupling)를 낮춰 유지보수성 향상
//
// 📌 채택하는 구현체들
//    - SimpleFocusDetectionService : Vision(70%) + CoreML(30%) 하이브리드 (메인)
//    - FocusDetectionService       : Vision 단독 방식 (대안)
//    - MLFocusDetectionService     : CoreML 중심 방식 (대안)
//
// ============================================================================

import Foundation
import AVFoundation
import Combine

// MARK: - Focus Detection Protocol
protocol FocusDetectionServiceProtocol: ObservableObject {
    // Published 프로퍼티
    var currentState: FocusState { get }
    var isAnalyzing: Bool { get }
    var faceAnalysisData: FaceAnalysisData { get }
    
    // 필수 메서드
    func processFrame(_ sampleBuffer: CMSampleBuffer)
    func reset()
}
