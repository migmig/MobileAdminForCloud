//
//  SourceBuildListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/14/25.
//

import SwiftUI

struct SourceBuildListView: View {
    @ObservedObject var viewModel:ViewModel
    @State var selectedSourceBuildProject:SourceBuildProject?
    @State var searchText:String = ""
    @Binding var selected:SourceBuildProject?
    /// 검색어 적용 후 환경별로 분류된 목록
    func list(for env: SourceEnvType) -> [SourceBuildProject] {
        viewModel.buildProjects.filter {
            SourceEnvType.of($0.name) == env
                && SourceEnvType.matches(name: $0.name, searchText: searchText)
        }
        .sorted(by: {$0.name < $1.name})
    }
    var body: some View {
        List(selection: $selected){
            if viewModel.buildProjects.isEmpty {
                EmptyStateView(
                    systemImage: "hammer",
                    title: "빌드 프로젝트가 없습니다"
                )
                .listRowBackground(Color.clear)
            }
            ForEach(SourceEnvType.allCases) { env in
                let items = list(for: env)
                if !items.isEmpty {
                    Section(env.title){
                        ForEach(items, id:\.id){ item in
                            #if os(iOS)
                            NavigationLink(destination:{
                                SourceBuildDetail(viewModel:viewModel,
                                                  selectedProject: item)
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
            }
        }
        .searchable(text: $searchText, placement: .automatic, prompt: "이름, 운영/스테이징/DR/개발 검색")
        .navigationTitle("소스빌드목록")
                  
        .onAppear(){
            if viewModel.buildProjects.isEmpty {
                Task{
                    let projects = await viewModel.fetchSourceBuildList()
                    
                    await MainActor.run{
                        viewModel.buildProjects = projects.result.project.sorted(by: {$0.id < $1.id})
                    }
                     
                }
            }
        }
    }
}

#Preview{
    NavigationStack{
        SourceBuildListView(viewModel: ViewModel(), selected:.constant(nil))
    }
}
