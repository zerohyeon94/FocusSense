//
//  DebugToolbar.swift
//  FocusSense
//
//  Created by 조영현 on 3/12/26.
//

import SwiftUI

// MARK: - Debug Toolbar
struct DebugToolbar: View {
    @Binding var isDebugMode: Bool
    @Binding var showCalibration: Bool
    let isCalibrated: Bool
    let isRunning: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 캘리브레이션 버튼
            Button(action: {
                showCalibration = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isCalibrated ? "checkmark.circle.fill" : "scope")
                        .font(.system(size: 14))
                    
                    Text(isCalibrated ? "위치 설정됨" : "위치 설정")
                        .font(.caption)
                }
                .foregroundColor(isCalibrated ? .green : .orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isCalibrated ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isCalibrated ? Color.green.opacity(0.5) : Color.orange.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                )
            }
            
            Spacer()
            
            // 기존 디버그 버튼
            Button(action: {
                isDebugMode = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 14))
                    
                    Text("AI 분석 보기")
                        .font(.caption)
                }
                .foregroundColor(isRunning ? .cyan : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isRunning ? Color.cyan.opacity(0.2) : Color.gray.opacity(0.2))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isRunning ? Color.cyan.opacity(0.5) : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .disabled(!isRunning)
            .opacity(isRunning ? 1 : 0.5)
        }
    }
}
