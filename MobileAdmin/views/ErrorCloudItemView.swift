//
//  ErrorCloudItemView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

struct ErrorCloudItemView: View {
    let errorCloudItem: ErrorCloudItem
    
    
    private var title: String {
        Date().formatted(Date.FormatStyle()
            .weekday(.abbreviated)
            .month(.abbreviated)
            .day()
            .year())
    }
    
    var body: some View {
        ScrollView{
            HStack{
                Text("User ID:")
                Text(errorCloudItem.userId!)
            }.padding()
            Text(errorCloudItem.msg!).padding()
            Text(errorCloudItem.traceCn!).padding()
            Text(errorCloudItem.restUrl!).padding()
            Text(errorCloudItem.registerDt!).padding()
            Text(errorCloudItem.requestInfo!).padding()
        }.frame(maxWidth:.infinity,alignment: .leading)
            .padding()
        #if os(iOS)
            .navigationTitle(title)
        #elseif os(macOS)
            .navigationSubtitle(title)
        #endif
    }
}
 
