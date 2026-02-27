//
//  EdcClsSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/8/24.
//

import SwiftUI

struct EdcClsSidebar: View {
    @EnvironmentObject var educationViewModel: EducationViewModel
    @Binding var selectedEdcCrseCl:EdcCrseCl?
    @State var isLoading:Bool = false
    var body: some View {
            if isLoading {
                ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
            }
            List(selection:$selectedEdcCrseCl){
                ForEach(educationViewModel.edcCrseCllist, id:\.self){  entry in
                    NavigationLink(destination : EdcCrseDetailView(
                        edcCrseClinfo:entry)){
                        HStack {
                            Image(systemName: SlidebarItem.gcpClsList.img)
                                .font(.caption)
                            Text("\(entry.id!) : \(entry.edcCrseName ?? "")")
                        }
                    }
                }
            }
         .navigationTitle("강의목록 조회")
#if os(macOS)
         .navigationSubtitle("  \(educationViewModel.edcCrseCllist.count)건의 강의")
#endif

         .onAppear(){
             Task{
                 isLoading = true
                 await educationViewModel.fetchClsLists()
                 isLoading = false
             }
         }
    }
}
