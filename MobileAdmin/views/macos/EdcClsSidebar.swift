//
//  EdcClsSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/8/24.
//

import SwiftUI

struct EdcClsSidebar: View {
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @Binding var edcCrseCl:[EdcCrseCl]
    @Binding var selectedEdcCrseCl:EdcCrseCl?
    @State var isLoading:Bool = false
    var body: some View {
        if isLoading {
            ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
        }
        List(selection:$selectedEdcCrseCl){
           ForEach(edcCrseCl, id:\.self){  entry in
                NavigationLink(value:entry){
                    HStack {
                        Image(systemName: SlidebarItem.gcpClsList.img)
                            .font(.caption)
                        Text(entry.edcCrseName ?? "")
                    }
                }
            }
        }
         .navigationTitle("강의목록 조회")
#if os(macOS)
         .navigationSubtitle("  \(edcCrseCl.count)건의 강의")
#endif
         
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

#Preview {
    EdcClsSidebar(
        edcCrseCl: .constant(
            Array(repeating: EdcCrseCl(
                "강의명",
                "강의소개"
            ), count: 15)
        ),
        selectedEdcCrseCl: .constant(nil)
    )
}