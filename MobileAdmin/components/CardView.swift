//
//  CardView.swift
//  MobileAdmin
//
//  공통 카드 컴포넌트 - 라운드 코너 + 그림자
//

import SwiftUI

struct CardView<Content: View>: View {
    var title: String?
    var systemImage: String?
    var content: Content

    init(
        title: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let title = title {
                HStack(spacing: AppSpacing.sm) {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                            .foregroundColor(AppColor.icon)
                            .font(AppFont.listSubtitle)
                    }
                    Text(title)
                        .font(AppFont.listTitle)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, AppSpacing.xxs)
            }
            content
        }
        .padding(AppSpacing.lg)
        #if os(iOS)
        .background(Color(.secondarySystemGroupedBackground))
        #else
        .background(Color(.controlBackgroundColor))
        #endif
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        CardView(title: "기본 정보", systemImage: "info.circle") {
            InfoRow(title: "이름", value: "홍길동")
            InfoRow(title: "코드", value: "A001")
        }
        CardView {
            Text("제목 없는 카드")
        }
    }
    .padding()
}
