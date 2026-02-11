
import SwiftUI

struct InfoRow: View {
    var title: String
    var value: String?

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .font(AppFont.caption)
            Spacer()
            Text(value ?? "")
                .fontWeight(.medium)
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value ?? "")")
        .contextMenu{
            Button("Copy"){
                Util.copyToClipboard(value ?? "")
            }
        }
    }
}

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

#Preview {
    VStack {
        InfoRow(title: "User ID:", value: "123456")
        InfoRowCustom(title: "Toggle:") {
            Toggle("", isOn: .constant(true)).labelsHidden()
        }
    }
    .padding()
}
