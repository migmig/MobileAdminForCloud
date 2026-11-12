//
//  SourcePipelineListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/17/25.
//

import SwiftUI

struct SourcePipelineListView: View {
    @ObservedObject var viewModel:ViewModel
    @State private var searchText:String = ""
    @Binding var selectedPipeline:SourceInfoProjectInfo?
    /// 검색어 적용 후 환경별로 분류된 목록
    func list(for env: SourceEnvType) -> [SourceInfoProjectInfo] {
        viewModel.sourcePipelineList.filter {
            SourceEnvType.of($0.name) == env
                && SourceEnvType.matches(name: $0.name, searchText: searchText)
        }
        .sorted(by: {$0.name < $1.name})
    }
    var body: some View {
        List(selection: $selectedPipeline){
            if viewModel.sourcePipelineList.isEmpty {
                EmptyStateView(
                    systemImage: "rectangle.connected.to.line.below",
                    title: "파이프라인이 없습니다"
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
                                SourcePipelineDetail(viewModel:viewModel,
                                                     selectedPipeline: item)
                            }){
                                SourcelineListSubView(itemNm:item.name)
                            }
                            #endif
                            #if os(macOS)
                            NavigationLink(value:item)
                            {
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
        .navigationTitle("파이프라인")
        .onAppear{
            Task{
                let response = await viewModel.fetchSourcePipelineList()
                viewModel.sourcePipelineList = response.result.projectList.sorted(by: {$0.id < $1.id})
            }
        }
    }
}
 

#Preview {
    NavigationStack{
        SourcePipelineListView(viewModel: ViewModel(), selectedPipeline: .constant(nil))
    }
}
