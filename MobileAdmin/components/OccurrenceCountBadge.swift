//
//  OccurrenceCountBadge.swift
//  MobileAdmin
//
//  오류 발생 횟수 배지 컴포넌트
//

import SwiftUI

struct OccurrenceCountBadge: View {
    let count: Int

    var countColor: Color {
        switch count {
        case 1:
            return .blue
        case 2...5:
            return .green
        case 6...10:
            return .orange
        default:
            return .red
        }
    }

    var countLabel: String {
        if count == 1 {
            return "1번"
        } else if count <= 99 {
            return "\(count)번"
        } else {
            return "99+"
        }
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "repeat")
                .font(AppFont.caption)
                .foregroundColor(countColor)

            Text(countLabel)
                .font(AppFont.caption)
                .fontWeight(.medium)
                .foregroundColor(countColor)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(countColor.opacity(0.15))
        .cornerRadius(AppRadius.xs)
        .accessibilityLabel("발생 횟수: \(countLabel)")
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            OccurrenceCountBadge(count: 1)
            OccurrenceCountBadge(count: 3)
            OccurrenceCountBadge(count: 7)
            OccurrenceCountBadge(count: 100)
        }
    }
    .padding()
}
