//
//  QuickStartCard.swift
//  FocusSense
//
//  Created by 조영현 on 3/12/26.
//

import SwiftUI

// MARK: - Quick Start Card
struct QuickStartCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("학습 시작하기")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("타이머를 시작하고 집중도를 측정해보세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
