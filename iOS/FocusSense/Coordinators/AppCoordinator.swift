//
//  AppCoordinator.swift
//  FocusSense
//
//  MVVM-C 패턴의 Coordinator
//  화면 전환 로직을 ViewModel에서 분리
//

import SwiftUI
import Combine

// MARK: - Navigation Destination
enum AppDestination: Hashable {
    case timer
    case analytics
    case settings
    case sessionDetail(sessionId: UUID)
}

// MARK: - App Coordinator
@MainActor
final class AppCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var path = NavigationPath()
    @Published var selectedTab: Int = 0
    @Published var showingSheet: SheetType?
    @Published var showingAlert: AlertType?
    
    // MARK: - Sheet Types
    enum SheetType: Identifiable {
        case sessionSummary(StudySession)
        case cameraPermission
        
        var id: String {
            switch self {
            case .sessionSummary: return "sessionSummary"
            case .cameraPermission: return "cameraPermission"
            }
        }
    }
    
    // MARK: - Alert Types
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
    func navigate(to destination: AppDestination) {
        path.append(destination)
    }
    
    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
    
    // MARK: - Tab Navigation
    func switchToTab(_ tab: Int) {
        selectedTab = tab
    }
    
    func showTimer() {
        switchToTab(0)
    }
    
    func showAnalytics() {
        switchToTab(1)
    }
    
    func showSettings() {
        switchToTab(2)
    }
    
    // MARK: - Sheet Methods
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
