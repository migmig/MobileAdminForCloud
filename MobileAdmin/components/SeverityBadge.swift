//
//  SeverityBadge.swift
//  MobileAdmin
//
//  오류 심각도 배지 컴포넌트
//

import SwiftUI

struct SeverityBadge: View {
    let severity: SeverityLevel
    var style: BadgeStyle = .full

    enum BadgeStyle {
        case full    // 아이콘 + 텍스트
        case compact // 아이콘만
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: severity.systemImage)
                .font(AppFont.caption)
                .foregroundColor(severity.color)

            if style == .full {
                Text(severity.displayName)
                    .font(AppFont.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(severity.color)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(severity.color.opacity(0.15))
        .cornerRadius(AppRadius.xs)
        .accessibilityLabel("심각도: \(severity.displayName)")
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            SeverityBadge(severity: .critical, style: .full)
            SeverityBadge(severity: .high, style: .full)
            SeverityBadge(severity: .medium, style: .full)
            SeverityBadge(severity: .low, style: .full)
        }

        HStack(spacing: 12) {
            SeverityBadge(severity: .critical, style: .compact)
            SeverityBadge(severity: .high, style: .compact)
            SeverityBadge(severity: .medium, style: .compact)
            SeverityBadge(severity: .low, style: .compact)
        }
    }
    .padding()
}
