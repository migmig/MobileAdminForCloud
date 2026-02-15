//
//  SeverityFilterView.swift
//  MobileAdmin
//
//  심각도별 필터 칩 컴포넌트
//

import SwiftUI

struct SeverityFilterView: View {
    @Binding var selectedSeverity: SeverityLevel?
    var severityItemCounts: [SeverityLevel: Int] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("심각도 필터")
                .font(AppFont.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: AppSpacing.sm) {
                // "모두" 버튼
                Button(action: {
                    selectedSeverity = nil
                }) {
                    Text("모두")
                        .font(AppFont.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedSeverity == nil ? .white : .primary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(selectedSeverity == nil ? Color.accentColor : Color.gray.opacity(0.2))
                        .cornerRadius(AppRadius.xl)
                }

                // 각 심각도별 칩
                ForEach(SeverityLevel.allCases, id: \.self) { severity in
                    Button(action: {
                        selectedSeverity = (selectedSeverity == severity) ? nil : severity
                    }) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: severity.systemImage)
                                .font(AppFont.caption)

                            VStack(alignment: .leading, spacing: 0) {
                                Text(severity.displayName)
                                    .font(AppFont.caption)
                                    .fontWeight(.semibold)

                                if let count = severityItemCounts[severity], count > 0 {
                                    Text("\(count)")
                                        .font(AppFont.captionSmall)
                                        .opacity(0.7)
                                }
                            }
                        }
                        .foregroundColor(selectedSeverity == severity ? .white : severity.color)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(selectedSeverity == severity ? severity.color : severity.color.opacity(0.15))
                        .cornerRadius(AppRadius.xl)
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

#Preview {
    SeverityFilterView(
        selectedSeverity: .constant(.high),
        severityItemCounts: [
            .critical: 5,
            .high: 12,
            .medium: 23,
            .low: 8
        ]
    )
}
