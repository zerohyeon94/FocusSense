//
//  SettingsView.swift
//  FocusSense
//
//  앱 설정 화면
//

import SwiftUI

struct SettingsView: View {
    /// @AppStorage: UserDefaults와 자동 연결
    /// - @AppStorage: Property Wrapper
    /// - "hapticEnabled": UserDefaults에 저장되는 키
    /// - hapticEnabled = true: 기본값 (처음 실행 시)
    /**
    @AppStorage 동작 방식:

    1. 앱 처음 실행: UserDefaults에 값 없음 → 기본값(true) 사용
    2. 사용자가 토글 변경 → 자동으로 UserDefaults에 저장
    3. 앱 재실행 → UserDefaults에서 값 로드

    UserDefaults.standard.bool(forKey: "hapticEnabled") 와 동일하지만
    SwiftUI와 자동 바인딩되어 훨씬 편리!
    Double, Int, String, Bool, Data, URL 타입 지원
    */
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autoPauseEnabled") private var autoPauseEnabled = true
    @AppStorage("drowsinessThreshold") private var drowsinessThreshold = 3.0
    
    var body: some View {
        NavigationStack {
            List {
                // 알림 설정
                Section { // Section: 그룹화된 항목들
                    /// Toggle 내부 동작:
                    /// 1. 사용자가 스위치 누름
                    /// 2. Toggle이 hapticEnabled를 반전 (true ↔ false)
                    /// 3. @AppStorage가 UserDefaults에 자동 저장
                    /// 4. UI 자동 업데이트
                    Toggle(isOn: $hapticEnabled) { // $ = Binding (양방향 연결): Toggle이 이 값을 읽고 쓸 수 있음
                        SettingRow(
                            icon: "iphone.radiowaves.left.and.right",
                            title: "진동 알림",
                            color: .purple
                        )
                    }
                    
                    Toggle(isOn: $soundEnabled) {
                        SettingRow(
                            icon: "speaker.wave.2.fill",
                            title: "소리 알림",
                            color: .orange
                        )
                    }
                } header: { // 섹션 헤더 (작은 회색 글씨)
                    Text("알림")
                }
                
                // 집중 감지 설정
                Section {
                    Toggle(isOn: $autoPauseEnabled) {
                        SettingRow(
                            icon: "pause.circle.fill",
                            title: "자동 일시정지",
                            color: .blue
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SettingRow(
                            icon: "moon.zzz.fill",
                            title: "졸음 감지 민감도",
                            color: .red
                        )
                        
                        /// Slider: 범위 선택
                        /// - $drowsinessThreshold: 현재 값 (Binding)
                        /// - in: 1...5: 범위
                        /// - step: 1: 증가 단위
                        Slider(value: $drowsinessThreshold, in: 1...5, step: 1) {
                            Text("민감도") // 접근성용 라벨 (화면에 안보임)
                        }
                        
                        /// value: 1.0 ~ 5.0 사이의 값
                        /// step: 1 단위로 증가
                        HStack {
                            Text("민감") // 왼쪽 끝 라벨
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("둔감") // 오른쪽 끝 라벨
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("집중 감지")
                } footer: { // 섹션 푸터 (아래 설명)
                    Text("민감도가 높을수록 작은 변화에도 졸음으로 감지합니다.")
                }
                
                // 개인정보 안내
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("개인정보 보호")
                                .font(.headline)
                        }
                        
                        Text("FocusSense는 모든 영상 분석을 기기 내에서만 처리합니다. 카메라 영상은 절대 외부 서버로 전송되지 않습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("개인정보")
                }
                
                // 앱 정보
                Section {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    // Link: 외부 URL 열기
                    Link(destination: URL(string: "https://github.com/zerohyeon94/FocusSense")!) { // !: 강제 언래핑 (URL이 유효하다고 가정)
                        HStack {
                            SettingRow(
                                icon: "chevron.left.forwardslash.chevron.right",
                                title: "소스 코드",
                                color: .gray
                            )
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("앱 정보")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
