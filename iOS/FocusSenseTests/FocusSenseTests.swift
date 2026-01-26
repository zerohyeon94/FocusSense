//
//  FocusSenseTests.swift
//  FocusSenseTests
//
//  Unit tests for FocusSense
//

import XCTest
@testable import FocusSense

final class FocusSenseTests: XCTestCase {
    
    // MARK: - FocusLevel Tests
    
    func testFocusLevelColors() {
        // Given
        let focused = FocusLevel.focused
        let drowsy = FocusLevel.drowsy
        
        // Then
        XCTAssertNotNil(focused.color)
        XCTAssertNotNil(drowsy.color)
    }
    
    func testFocusLevelDescriptions() {
        // Given
        let allLevels = FocusLevel.allCases
        
        // Then
        for level in allLevels {
            XCTAssertFalse(level.description.isEmpty, "\(level) should have a description")
            XCTAssertFalse(level.icon.isEmpty, "\(level) should have an icon")
        }
    }
    
    // MARK: - FocusState Tests
    
    func testFocusStateInitialization() {
        // When
        let state = FocusState()
        
        // Then
        XCTAssertEqual(state.level, .unknown)
        XCTAssertFalse(state.isFaceDetected)
        XCTAssertFalse(state.isLookingAtScreen)
    }
    
    func testFocusStateEquality() {
        // Given
        let state1 = FocusState(level: .focused, isFaceDetected: true)
        let state2 = FocusState(level: .focused, isFaceDetected: true)
        
        // Then - Each state has unique ID
        XCTAssertNotEqual(state1, state2)
    }
    
    // MARK: - HeadPose Tests
    
    func testHeadPoseLookingForward() {
        // Given - small angles (looking forward)
        let forwardPose = HeadPose(pitch: 5, yaw: 10, roll: 5)
        
        // Then
        XCTAssertTrue(forwardPose.isLookingForward)
    }
    
    func testHeadPoseLookingAway() {
        // Given - large yaw (looking to the side)
        let sidewaysPose = HeadPose(pitch: 0, yaw: 45, roll: 0)
        
        // Then
        XCTAssertFalse(sidewaysPose.isLookingForward)
    }
    
    // MARK: - EAR Constants Tests
    
    func testEARConstants() {
        // Then
        XCTAssertLessThan(EARConstants.drowsinessThreshold, EARConstants.blinkThreshold)
        XCTAssertGreaterThan(EARConstants.consecutiveFramesForDrowsiness, 0)
    }
    
    // MARK: - StudySession Tests
    
    func testStudySessionInitialization() {
        // When
        let session = StudySession()
        
        // Then
        XCTAssertNil(session.endTime)
        XCTAssertTrue(session.focusRecords.isEmpty)
        XCTAssertEqual(session.focusRate, 0)
    }
    
    func testStudySessionFocusRate() {
        // Given
        var session = StudySession()
        
        // Add some records
        session.focusRecords.append(FocusRecord(level: .focused, duration: 60))
        session.focusRecords.append(FocusRecord(level: .focused, duration: 60))
        session.focusRecords.append(FocusRecord(level: .drowsy, duration: 30))
        session.focusRecords.append(FocusRecord(level: .unfocused, duration: 30))
        
        // Set end time to make totalDuration calculable
        session.endTime = session.startTime.addingTimeInterval(180)
        
        // Then - 120 focused out of 180 total = 66.67%
        XCTAssertEqual(session.netFocusTime, 120, accuracy: 0.1)
    }
    
    func testStudySessionDrowsinessCount() {
        // Given
        var session = StudySession()
        session.focusRecords.append(FocusRecord(level: .drowsy, duration: 1))
        session.focusRecords.append(FocusRecord(level: .focused, duration: 1))
        session.focusRecords.append(FocusRecord(level: .drowsy, duration: 1))
        
        // Then
        XCTAssertEqual(session.drowsinessCount, 2)
    }
    
    func testFormattedDuration() {
        // Given
        var session = StudySession()
        session.endTime = session.startTime.addingTimeInterval(3661) // 1h 1m 1s
        
        // Then
        XCTAssertTrue(session.formattedTotalDuration.contains("시간"))
    }
}

// MARK: - FocusRecord Tests

final class FocusRecordTests: XCTestCase {
    
    func testFocusRecordInitialization() {
        // When
        let record = FocusRecord(level: .focused, duration: 5.0)
        
        // Then
        XCTAssertEqual(record.level, .focused)
        XCTAssertEqual(record.duration, 5.0)
    }
}
