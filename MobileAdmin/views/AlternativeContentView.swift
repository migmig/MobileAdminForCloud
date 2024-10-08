//
//  MainView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

struct AlternativeContentView: View {
    
    @StateObject var viewModel = ViewModel()
    @State private var toast:Toast?
    @State private var errorItems:[ErrorCloudItem] = []
    @State private var selectedEntry:ErrorCloudItem? = nil
    
    var body: some View {
        NavigationSplitView{
            List(errorItems,selection:$selectedEntry){entry in
                NavigationLink(value:entry){
                    ErrorCloudListItem(errorCloudItem: entry)
                }
            }
            .navigationSplitViewColumnWidth(min:200,ideal: 200)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                ToolbarItem{
                    Button{
                        viewModel.fetchErrors(completion:{
                            result in errorItems = result ?? []
                        }, startFrom: "2024-10-08", endTo:  "2024-10-08")
                        viewModel.fetchToasts{ result in
                            toast = result
                        }
                    }label:{
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                    }
                }
            }
        }detail:{
            DetailView(selectedEntry: $selectedEntry)
        }
    }
}
 
#Preview{
    AlternativeContentView()
}
