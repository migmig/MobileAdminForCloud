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
                    Text("       \(Util.formattedDate(errorCloudItem.registerDt ?? "").prefix(19))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(errorCloudItem.userId ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview(
"Content",
traits: .fixedLayout(width: 200, height: 500)
)
{
    List{
        ForEach(0..<10){idx in
            ErrorCloudListItem(errorCloudItem: ErrorCloudItem(
                code: "code\(idx)",
                description: "description\(idx)",
                msg: "msg\(idx)",
                registerDt : Util.getCurrentDateString(),
                requestInfo: "requestInfo",
                restUrl: "restUrl",
                traceCn: "traceCn",
                userId: "userId\(idx)"
            ))
        }
    
    }
}
