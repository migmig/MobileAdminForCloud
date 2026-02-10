import SwiftUI

// MARK: - ViewBuilder 기반 커스텀 콘텐츠 Row
struct InfoRowCustom<Content: View>: View {
    var title: String
    var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .font(AppFont.caption)
            Spacer()
            content
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// 하위호환을 위해 기존 이름 유지
typealias InfoRow2 = InfoRowCustom
typealias InfoRow4 = InfoRowCustom

#Preview {
    InfoRowCustom(title: "User ID:") {
        Text("123456")
    }
    .previewLayout(.sizeThatFits)
}
