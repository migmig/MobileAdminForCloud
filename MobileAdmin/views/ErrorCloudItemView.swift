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
            VStack{
                Section(header: Text("상세 정보").font(.headline)) {
                    InfoRow(title: "User ID:", value: errorCloudItem.userId ?? "")
                    Divider()
                    InfoRow(title: "Code:", value: errorCloudItem.code ?? "")
                    Divider()
                    InfoRow(title: "Description", value: errorCloudItem.description ?? "")
                    Divider()
                    InfoRow(title: "Msg", value: errorCloudItem.msg ?? "")
                    Divider()
                    InfoRow(title: "Trace", value: errorCloudItem.traceCn ?? "")
                    Divider()
                    InfoRow(title: "Reqest URL", value: errorCloudItem.restUrl ?? "")
                    Divider()
                    InfoRow(title: "Register DT", value: Util.formattedDate(from:errorCloudItem.registerDt ?? ""))
                    Divider()
                    InfoRow(title: "Request Info", value: Util.formatRequestInfo(errorCloudItem.requestInfo ?? ""))
                    Divider()
                }
            }
//            
//            LazyVGrid(columns: [GridItem(.fixed(100)), GridItem(.flexible())], alignment: .leading) {
//                Group {
//                    Text("User ID:")
//                    Text(errorCloudItem.userId ?? "")
//                    
//                    Text("Code:")
//                    Text(errorCloudItem.code ?? "")
//                    
//                    Text("Description:")
//                    Text(errorCloudItem.description  ?? "")
//                    
//                    Text("Msg:")
//                    Text(errorCloudItem.msg  ?? "")
//                    
//                    Text("Trace CN:")
//                    ScrollView([.vertical,.horizontal]){
//                        Text(errorCloudItem.traceCn  ?? "")
//                            .truncationMode(.tail)
//                            .multilineTextAlignment(.leading)
//                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
//                    }
//                    
//                    Text("Rest URL:")
//                    Text(errorCloudItem.restUrl ?? "")
//                    
//                    Text("Register DT:")
//                    Text(Util.formattedDate(from:errorCloudItem.registerDt ?? ""))
//                    
//                    Text("Request Info:")
//                    ScrollView([.vertical,.horizontal]){
//                        Text(Util.formatRequestInfo(errorCloudItem.requestInfo ?? ""))
//                            .padding(.vertical, 4)
//                            .multilineTextAlignment(.leading)
//                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
//                    }
//                }
//                .padding(.vertical, 4)
//            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        #if os(iOS)
        .navigationTitle(Util.formattedDate(from:errorCloudItem.registerDt ?? ""))
        #elseif os(macOS)
        .navigationSubtitle(Util.formattedDate(from:errorCloudItem.registerDt ?? ""))
        #endif
    }
}
 
#Preview{
    ErrorCloudItemView(errorCloudItem: .init(description: "Error description", userId: "Error"))
}
 
