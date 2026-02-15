//
//  EmptyStateView.swift
//  MobileAdmin
//
//  공통 빈 상태 뷰 - 데이터 없을 때 표시
//

import SwiftUI

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var description: String?
    var iconColor: Color = .secondary.opacity(0.6)

    init(systemImage: String, title: String, description: String? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.description = description
        self.iconColor = .secondary.opacity(0.6)
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
            Text(title)
                .font(AppFont.listTitle)
                .foregroundColor(.secondary)
            if let description = description {
                Text(description)
                    .font(AppFont.caption)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(AppSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(description != nil ? "\(title), \(description!)" : title)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "tray",
        title: "데이터가 없습니다",
        description: "조회 조건을 변경해 보세요"
    )
}
