
import SwiftUI

struct InfoRow: View {
    var title: String
    var value: String?
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
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
