//
//  ErrorCloudItemView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

struct ErrorCloudItemView: View {
    let errorCloudItem: ErrorCloudItem
     
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.fixed(100)), GridItem(.flexible())], alignment: .leading) {
                Group {
                    Text("User ID:")
                    Text(errorCloudItem.userId!)
                    
                    Text("Code:")
                    Text(errorCloudItem.code!)
                    
                    Text("Description:")
                    Text(errorCloudItem.description!)
                    
                    Text("Msg:")
                    Text(errorCloudItem.msg!)
                    
                    Text("Trace CN:")
                    ScrollView([.vertical,.horizontal]){
                        Text(errorCloudItem.traceCn!)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Text("Rest URL:")
                    Text(errorCloudItem.restUrl!)
                    
                    Text("Register DT:")
                    Text(Util.formattedDate(from:errorCloudItem.registerDt!))
                    
                    Text("Request Info:")
                    ScrollView([.vertical,.horizontal]){
                        Text(Util.formatRequestInfo(errorCloudItem.requestInfo!))
                            .padding(.vertical, 4)
                            .multilineTextAlignment(.leading)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        #if os(iOS)
        .navigationTitle(Util.formattedDate(from:errorCloudItem.registerDt!))
        #elseif os(macOS)
        .navigationSubtitle(Util.formattedDate(from:errorCloudItem.registerDt!))
        #endif
    }
}
 

 
