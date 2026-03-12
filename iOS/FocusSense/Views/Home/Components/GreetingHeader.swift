//
//  GreetingHeader.swift
//  FocusSense
//
//  Created by 조영현 on 3/12/26.
//

import SwiftUI

// MARK: - Greeting Header
// 📚 View 분리 패턴:
//    DashboardView가 커지지 않도록 하위 컴포넌트를 별도 struct로 분리합니다.
//    프로젝트 CLAUDE.md 규칙: "View가 100줄 이상이면 별도의 struct로 분리"
//    이 패턴의 장점:
//    - 각 컴포넌트를 독립적으로 Preview 가능
//    - 코드 가독성 향상
//    - 재사용 가능한 컴포넌트 생성
struct GreetingHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // 📚 computed property를 사용하여 인사말 텍스트를 생성합니다.
                //    body 안에 복잡한 로직을 두지 않고 별도 프로퍼티로 분리하면
                //    body의 가독성이 유지됩니다.
                Text(greetingText)
                    .font(.title2.bold())
                Text(todayDateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer() // 📚 Spacer: 남은 공간을 차지하여 VStack을 왼쪽 정렬시킵니다.
        }
    }

    // 📚 시간대별 인사말 로직:
    //    Calendar.current.component(.hour, from: Date())로 현재 시간을 가져옵니다.
    //    switch + Range 패턴 매칭으로 시간대를 깔끔하게 분기합니다.
    //    - 5..<12: 5시 이상 12시 미만 (아침)
    //    - 12..<17: 12시 이상 17시 미만 (오후)
    //    - 17..<21: 17시 이상 21시 미만 (저녁)
    //    - default: 나머지 (21시~4시, 늦은 밤)
    //    private: 이 struct 내부에서만 사용하는 도우미 프로퍼티임을 명시합니다.
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "좋은 아침이에요"
        case 12..<17: return "좋은 오후에요"
        case 17..<21: return "좋은 저녁이에요"
        default:      return "늦은 시간 화이팅"
        }
    }

    // 📚 DateFormatter: 날짜를 문자열로 변환합니다.
    //    Locale(identifier: "ko_KR"): 한국어 형식으로 표시 (예: "2월 23일 일요일")
    //    dateFormat "M월 d일 EEEE": M=월, d=일, EEEE=요일(전체)
    //    주의: DateFormatter는 생성 비용이 높으므로, 성능이 중요한 경우
    //    static let으로 캐싱하는 것이 좋습니다. (이 경우 뷰가 자주 다시 그려지지 않으므로 괜찮음)
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }
}
