//
//  TimerViewModel.swift
//  FocusSense
//
//  타이머 및 집중도 추적 관리
//

import Foundation
import Combine
import AVFoundation
import UIKit

// MARK: - Timer State
enum TimerState {
    case idle       // 대기
    case running    // 실행 중
    case paused     // 일시정지
    case autoPaused // 자동 일시정지 (졸음/이탈)
}

// MARK: - Timer ViewModel
@MainActor
final class TimerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var timerState: TimerState = .idle
    @Published var elapsedTime: TimeInterval = 0
    @Published var netFocusTime: TimeInterval = 0
    @Published var currentFocusState: FocusState = FocusState()
    @Published var currentSession: StudySession?
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // MARK: - Services
    private let cameraService: CameraService
    private let focusDetectionService: FocusDetectionService
    
    // MARK: - Timer
    private var timer: Timer?
    private var focusCheckTimer: Timer?
    
    // MARK: - Thermal Monitoring
    private var thermalStateObserver: NSObjectProtocol?
    
    // MARK: - Haptic Feedback
    private let hapticGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Auto Pause Settings
    private var consecutiveUnfocusedCount = 0
    private let autoPauseThreshold = 3  // 3초 연속 이탈 시 자동 일시정지
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var formattedElapsedTime: String {
        formatTime(elapsedTime)
    }
    
    var formattedNetFocusTime: String {
        formatTime(netFocusTime)
    }
    
    var focusRate: Double {
        guard elapsedTime > 0 else { return 0 }
        return (netFocusTime / elapsedTime) * 100
    }
    
    // MARK: - Initialization
    init() {
        self.cameraService = CameraService()
        self.focusDetectionService = FocusDetectionService()
        
        setupBindings()
        setupThermalMonitoring()
    }
    
    deinit {
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // 카메라 -> 집중도 감지 연결
        cameraService.delegate = self
        focusDetectionService.delegate = self
        
        // 집중도 상태 변화 구독
        focusDetectionService.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleFocusStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func setupThermalMonitoring() {
        // 발열 상태 모니터링
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleThermalStateChange()
        }
    }
    
    // MARK: - Timer Control
    func startTimer() {
        guard timerState == .idle || timerState == .paused else { return }
        
        // 새 세션 시작 또는 기존 세션 재개
        if currentSession == nil {
            currentSession = StudySession()
        }
        
        timerState = .running
        cameraService.start()
        
        // 1초마다 타이머 업데이트
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
        
        print("▶️ Timer started")
    }
    
    func pauseTimer() {
        guard timerState == .running else { return }
        
        timerState = .paused
        timer?.invalidate()
        timer = nil
        cameraService.stop()
        
        print("⏸️ Timer paused")
    }
    
    func resumeTimer() {
        guard timerState == .paused || timerState == .autoPaused else { return }
        
        timerState = .running
        consecutiveUnfocusedCount = 0
        cameraService.start()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
        
        print("▶️ Timer resumed")
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        cameraService.stop()
        
        // 세션 종료
        currentSession?.endTime = Date()
        
        timerState = .idle
        
        print("⏹️ Timer stopped")
    }
    
    func resetTimer() {
        stopTimer()
        elapsedTime = 0
        netFocusTime = 0
        currentSession = nil
        focusDetectionService.reset()
        consecutiveUnfocusedCount = 0
        
        print("🔄 Timer reset")
    }
    
    // MARK: - Timer Update
    private func updateTimer() {
        elapsedTime += 1
        
        // 집중 상태일 때만 순수 집중 시간 증가
        if currentFocusState.level == .focused {
            netFocusTime += 1
        }
        
        // 세션에 기록 추가
        let record = FocusRecord(
            timestamp: Date(),
            level: currentFocusState.level,
            duration: 1.0
        )
        currentSession?.focusRecords.append(record)
    }
    
    // MARK: - Focus State Handling
    private func handleFocusStateChange(_ state: FocusState) {
        currentFocusState = state
        
        // 자동 일시정지 로직
        if timerState == .running {
            if state.level == .drowsy || state.level == .unfocused {
                consecutiveUnfocusedCount += 1
                
                if consecutiveUnfocusedCount >= autoPauseThreshold {
                    triggerAutoPause(reason: state.level)
                }
            } else {
                consecutiveUnfocusedCount = 0
            }
        }
    }
    
    private func triggerAutoPause(reason: FocusLevel) {
        timerState = .autoPaused
        timer?.invalidate()
        timer = nil
        // 카메라는 계속 실행 (복귀 감지를 위해)
        
        // 햅틱 피드백
        hapticGenerator.notificationOccurred(.warning)
        
        // 알림 메시지 설정
        switch reason {
        case .drowsy:
            alertMessage = "😴 졸음이 감지되었어요!\n잠시 환기하고 돌아오세요."
        case .unfocused:
            alertMessage = "👀 자리를 비우셨나요?\n돌아오시면 자동으로 재개됩니다."
        default:
            alertMessage = "집중이 흐트러졌어요."
        }
        showAlert = true
        
        print("⚠️ Auto-paused: \(reason.rawValue)")
    }
    
    // MARK: - Thermal Handling
    private func handleThermalStateChange() {
        let thermalState = ProcessInfo.processInfo.thermalState
        cameraService.adjustFrameInterval(for: thermalState)
        
        if thermalState == .critical {
            // 위험 수준 발열 시 분석 중지하고 알림
            alertMessage = "🔥 기기가 과열되었습니다.\n잠시 후 다시 시도해주세요."
            showAlert = true
            pauseTimer()
        }
    }
    
    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - CameraServiceDelegate
extension TimerViewModel: CameraServiceDelegate {
    nonisolated func cameraService(_ service: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
        // 카메라 프레임을 집중도 감지 서비스로 전달
        focusDetectionService.processFrame(sampleBuffer)
    }
    
    nonisolated func cameraService(_ service: CameraService, didFailWithError error: Error) {
        Task { @MainActor in
            alertMessage = "카메라 오류: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - FocusDetectionDelegate
extension TimerViewModel: FocusDetectionDelegate {
    nonisolated func focusDetection(_ service: FocusDetectionService, didDetect state: FocusState) {
        // 이미 Published 변수로 바인딩되어 있음
    }
}
