import SwiftUI

struct ErrorCloudListItem: View {
    let errorCloudItem: ErrorCloudItem
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text(errorCloudItem.description ?? errorCloudItem.msg ?? "")
                .lineLimit(3)
                .truncationMode(.tail)
            VStack(alignment: .trailing) {
                Text(errorCloudItem.userId ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
} 
