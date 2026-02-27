//
//  EdcClsSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/8/24.
//

import SwiftUI

struct EdcClsSidebarIOS: View {
    @EnvironmentObject var educationViewModel: EducationViewModel
    @State var selectedEdcCrseCl:EdcCrseCl? = nil
    @State var isLoading:Bool = false
    var body: some View {
        if isLoading {
            ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
        }
        List{
            if !isLoading && educationViewModel.edcCrseCllist.isEmpty {
                EmptyStateView(
                    systemImage: "graduationcap",
                    title: "교육 과정이 없습니다"
                )
                .listRowBackground(Color.clear)
            }
            ForEach(educationViewModel.edcCrseCllist, id:\.id){  entry in
                NavigationLink(destination:EdcCrseDetailView(edcCrseClinfo: entry)){
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
            if educationViewModel.edcCrseCllist.isEmpty {
                Task{
                    isLoading = true
                    await educationViewModel.fetchClsLists()
                    isLoading = false
                }
            }
        }
    }
}
