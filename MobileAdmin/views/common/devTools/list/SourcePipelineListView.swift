//
//  SourcePipelineListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/17/25.
//

import SwiftUI

struct SourcePipelineListView: View {
    @ObservedObject var viewModel:ViewModel
    @Binding var selectedPipeline:SourceInfoProjectInfo?
    var prodList:[SourceInfoProjectInfo] {
        viewModel.sourcePipelineList.filter{
            return $0.name.localizedStandardContains("prod")
        }
        .sorted(by: {$0.name < $1.name})
    }
    
    var devList:[SourceInfoProjectInfo] {
        viewModel.sourcePipelineList.filter{
            return !$0.name.localizedStandardContains("prod")
        }
        .sorted(by: {$0.name < $1.name})
    }
    var body: some View {
        List(selection: $selectedPipeline){
            Section("운영"){
                ForEach(prodList, id:\.id){ item in
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
.font(.title2)
#endif
            Section("개발"){
                ForEach(devList, id:\.id){ item in
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
.font(.title2)
#endif
        }
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
