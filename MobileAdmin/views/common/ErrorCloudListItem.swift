import SwiftUI

struct ErrorCloudListItem: View {
    let errorCloudItem: ErrorCloudItem
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack{
                Image(systemName:"checkmark.message")
                Text(errorCloudItem.description ?? errorCloudItem.msg ?? "")
#if os(iOS)
                    .lineLimit(2)
#elseif os(macOS)
                    .lineLimit(3)
#endif 
                    .truncationMode(.tail)
            }
            VStack(alignment: .trailing) {
                HStack{
                    Spacer()
                    Text(errorCloudItem.userId ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
