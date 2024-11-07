import SwiftUI

struct InfoRow2<Content: View>: View {
    var title: String
    var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            content
        }
        .padding(.vertical, 10)
    }
}

struct InfoRow2_Previews: PreviewProvider {
    static var previews: some View {
        InfoRow2(title: "User ID:") {
            Spacer()
            Divider()
            Text("123456")
        }
        .previewLayout(.sizeThatFits)
    }
}
