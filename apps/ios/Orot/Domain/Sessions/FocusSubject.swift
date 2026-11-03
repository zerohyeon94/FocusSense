//
//  FocusSubject.swift
//  Orot
//
//  집중 대상 (학습 · 업무 · 과제 등). 세션 설정 칩에 보이는 순서대로 정렬합니다.
//

import Foundation
import SwiftData

@Model
final class FocusSubject {
    var id: UUID
    var name: String
    var order: Int
    var createdAt: Date

    init(id: UUID = UUID(), name: String, order: Int) {
        self.id = id
        self.name = name
        self.order = order
        self.createdAt = Date()
    }

    static let maxNameLength = 12
    static let maxCount = 8
    static let defaultNames = ["학습", "업무", "과제"]
}
