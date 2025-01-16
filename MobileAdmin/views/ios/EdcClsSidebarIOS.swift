//
//  EdcClsSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/8/24.
//

import SwiftUI

struct EdcClsSidebarIOS: View {
    @ObservedObject var viewModel:ViewModel
    //@State var edcCrseCl:[EdcCrseCl] = []
    @State var selectedEdcCrseCl:EdcCrseCl? = nil
    @State var isLoading:Bool = false
    var body: some View { 
        if isLoading {
            ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
        }
        List{
            ForEach(viewModel.edcCrseCllist, id:\.id){  entry in
                NavigationLink(destination:EdcCrseDetailView(viewModel:viewModel, edcCrseClinfo: entry)){
                    HStack {
                        Image(systemName: SlidebarItem.gcpClsList.img)
                            .font(.caption)
                        Text(entry.edcCrseName ?? "")
                    }
                }
            }
        }
        .navigationTitle("교육 조회")
        .onAppear(){
            if viewModel.edcCrseCllist.isEmpty {
                Task{
                    isLoading = true
                    let edcCrseClListResponse:EdcCrseClListResponse =  await viewModel.fetchClsLists()
                    viewModel.edcCrseCllist = edcCrseClListResponse.edcCrseClAllList ?? []
                    isLoading = false
                }
            }
        }
    }
}
 
