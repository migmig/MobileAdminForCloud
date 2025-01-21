//
//  SourcePipelineListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/17/25.
//

import SwiftUI

struct SourcePipelineListView: View {
    @ObservedObject var viewModel:ViewModel
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
        List{
            Section("운영"){
                ForEach(prodList, id:\.id){ item in
                    NavigationLink(destination:{
                        SourcePipelineDetail(viewModel:viewModel,
                                             selectedPipeline: item)
                    }){
                        HStack{
                            Image(systemName: item.name.contains("prod") ? Util.getDevTypeImg("prod") : Util.getDevTypeImg("dev"))
                                .foregroundColor(item.name.contains("prod") ? Util.getDevTypeColor("prod") : Util.getDevTypeColor("dev"))
                            Text(item.name)
                        }
                    }
                }
            }
#if os(macOS)
.font(.title2)
#endif
            Section("개발"){
                ForEach(devList, id:\.id){ item in
                    NavigationLink(destination:{
                        SourcePipelineDetail(viewModel:viewModel,
                                             selectedPipeline: item)
                    }){
                        HStack{
                            Image(systemName: item.name.contains("prod") ? Util.getDevTypeImg("prod") : Util.getDevTypeImg("dev"))
                                .foregroundColor(item.name.contains("prod") ? Util.getDevTypeColor("prod") : Util.getDevTypeColor("dev"))
                            Text(item.name)
                        }
                    }
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
    SourcePipelineListView(viewModel: ViewModel())
}
