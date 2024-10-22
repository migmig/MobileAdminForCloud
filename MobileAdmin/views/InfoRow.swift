
import SwiftUI

struct InfoRow: View {
    var title: String
    var value: String
    
    var body: some View {
        HStack {
            Text(title)
                //.foregroundColor(.black)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
    }
}
