//
//  FocusDetectionServiceProtocol.swift
//  FocusSense
//
//  Vision / CoreML 서비스의 공통 인터페이스
//

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
