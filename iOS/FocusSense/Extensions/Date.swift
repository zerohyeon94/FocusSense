//
//  Date.swift
//  FocusSense
//
//  Created by 조영현 on 3/12/26.
//

import Foundation

extension Date {
    // ✨ 핵심: static let으로 선언하여 앱 실행 중 딱 한 번만 메모리에 올립니다.
    private static let debugFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.timeZone = TimeZone.current // 기기의 현재 시간대 (한국이면 KST)
        return formatter
    }()
    
    // 문자열을 반환하는 연산 프로퍼티
    var debugString: String {
        return Date.debugFormatter.string(from: self)
    }
    
    // 곧바로 콘솔에 출력해주는 헬퍼 함수
    func printLog(prefix: String = "Date") {
        print("\(prefix): \(self.debugString)")
    }
}
