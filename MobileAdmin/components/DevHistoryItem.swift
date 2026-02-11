//
//  DevHistoryItem.swift
//  MobileAdmin
//
//  DevTools 공통 이력 아이템 컴포넌트
//

import SwiftUI

struct DevHistoryItem: View {
    var statusColor: Color
    var status: String
    var beginTime: String
    var endTime: String
    var subtitle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                // 상태 뱃지
                Text(status)
                    .font(AppFont.captionSmall)
                    .fontWeight(.semibold)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(statusColor.opacity(0.12))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)

                Spacer()

                if !subtitle.isEmpty {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person.circle")
                            .font(AppFont.captionSmall)
                        Text(subtitle)
                            .font(AppFont.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            HStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "play.circle")
                        .font(AppFont.captionSmall)
                    Text(beginTime)
                        .font(AppFont.timestamp)
                        .monospacedDigit()
                }
                .foregroundColor(.secondary)

                Image(systemName: "arrow.right")
                    .font(AppFont.captionSmall)
                    .foregroundColor(.secondary)

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "stop.circle")
                        .font(AppFont.captionSmall)
                    Text(endTime)
                        .font(AppFont.timestamp)
                        .monospacedDigit()
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

#Preview {
    List {
        DevHistoryItem(
            statusColor: .blue,
            status: "success",
            beginTime: "2025-01-15 10:00:00",
            endTime: "2025-01-15 10:05:30",
            subtitle: "user01"
        )
        DevHistoryItem(
            statusColor: .red,
            status: "fail",
            beginTime: "2025-01-15 09:00:00",
            endTime: "2025-01-15 09:01:00",
            subtitle: "user02"
        )
    }
}
