//
//  SourceDeployListView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/20/25.
//

import SwiftUI

struct SourceDeployListView: View {
    @ObservedObject var viewModel:ViewModel
    @Binding var selectedDeploy:SourceInfoProjectInfo?
    var prodList:[SourceInfoProjectInfo] {
        viewModel.sourceDeployList.filter{
            return $0.name.localizedStandardContains("prod")
        }
        .sorted(by: {$0.name < $1.name})
    }
    
    var devList:[SourceInfoProjectInfo] {
        viewModel.sourceDeployList.filter{
            return !$0.name.localizedStandardContains("prod")
        }
        .sorted(by: {$0.name < $1.name})
    }
    var body: some View {
        List(selection: $selectedDeploy){
            if viewModel.sourceDeployList.isEmpty {
                EmptyStateView(
                    systemImage: "arrow.up.circle",
                    title: "배포 프로젝트가 없습니다"
                )
                .listRowBackground(Color.clear)
            }
            Section("운영"){
                ForEach(prodList, id:\.id){ item in
                    #if os(iOS)
                    NavigationLink(destination:{
                        SourceDeployDetail(viewModel:viewModel,
                                             selectedDeploy: item)
                    }){
                        SourcelineListSubView(itemNm:item.name)
                    }
                    #endif
                    #if os(macOS)
                    NavigationLink(value:item){
                        SourcelineListSubView(itemNm:item.name)
                    }
                    #endif
                }
            }
#if os(macOS)
.font(AppFont.sidebarItem)
#endif
            Section("개발"){
                ForEach(devList, id:\.id){ item in
                    #if os(iOS)
                    NavigationLink(destination:{
                        SourceDeployDetail(viewModel:viewModel,
                                             selectedDeploy: item)
                    }){
                        SourcelineListSubView(itemNm:item.name)
                    }
                    #endif
                    #if os(macOS)
                    NavigationLink(value:item){
                        SourcelineListSubView(itemNm:item.name)
                    }
                    #endif
                }
                
            }
#if os(macOS)
.font(AppFont.sidebarItem)
#endif
        }
        .navigationTitle("소스배포")
        .onAppear{
            Task{
                let response = await viewModel.fetchSourceDeployList()
                viewModel.sourceDeployList = response.result.projectList.sorted(by: {$0.id < $1.id})
            }
        }
    }
}
  
#Preview{
    NavigationStack{
        SourceDeployListView(viewModel: ViewModel()
                             , selectedDeploy: .constant(nil))
    }
}
