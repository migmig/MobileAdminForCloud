
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
        .contextMenu{
            Button("Copy"){
                Util.copyToClipboard(value ?? "")
            }
        }
    }
}

#Preview {
    InfoRow(title: "User ID:", value: "123456")
}
