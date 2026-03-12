//
//  SettingRow.swift
//  FocusSense
//
//  Created by 조영현 on 3/11/26.
//

import SwiftUI

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
