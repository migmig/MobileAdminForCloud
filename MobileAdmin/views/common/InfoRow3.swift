
import SwiftUI

struct InfoRow3: View {
    var title: String
    var value: String?
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "")
                .foregroundColor(.secondary)
        } 
        .contextMenu{
            Button("Copy"){
                Util.copyToClipboard(value ?? "")
            }
        }
    }
}

#Preview {
    InfoRow3(title: "User ID:", value: "123456")
}
