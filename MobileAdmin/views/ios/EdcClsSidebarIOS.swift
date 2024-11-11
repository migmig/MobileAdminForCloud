//
//  EdcClsSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/8/24.
//

import SwiftUI

struct EdcClsSidebarIOS: View {
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @State var edcCrseCl:[EdcCrseCl] = []
    @State var selectedEdcCrseCl:EdcCrseCl? = nil
    @State var isLoading:Bool = false
    var body: some View {
        NavigationStack{
            if isLoading {
                ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
            }else{
                List{
                    ForEach(edcCrseCl, id:\.id){  entry in
                        NavigationLink(value:entry){
                            HStack {
                                Image(systemName: SlidebarItem.gcpClsList.img)
                                    .font(.caption)
                                Text(entry.edcCrseName ?? "")
                            }
                        }
                    }
                }
                .navigationDestination(for:EdcCrseCl.self){item in
                    EdcCrseDetailView(viewModel:viewModel, edcCrseClinfo: item)
                }
            }
        }
         .navigationTitle("강의목록 조회")
         .onAppear(){
             Task{
                 isLoading = true
                 let edcCrseClListResponse:EdcCrseClListResponse =  await viewModel.fetchClsLists()
                 print(
                     "\n\n\(String(describing: edcCrseClListResponse.edcCrseClAllList))\n\n"
                 )
                 edcCrseCl = edcCrseClListResponse.edcCrseClAllList ?? []
                 isLoading = false
             }
         }
    }
}
 
