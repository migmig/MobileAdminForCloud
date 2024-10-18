//
//  ErrorCloudListItem.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

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
 #Preview {
     ErrorCloudListItem(errorCloudItem: ErrorCloudItem(code: "asdf1", description: "asdf2", id: 1, msg: "asdf", registerDt: "asdf", requestInfo: "asdf", restUrl: "asdf", traceCn: "asdf", userId: "asdf3"))
}

