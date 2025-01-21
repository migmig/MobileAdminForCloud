//
//  SourceDeployListView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/20/25.
//

import SwiftUI

struct SourceDeployListView: View {
    @ObservedObject var viewModel:ViewModel
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
        List{
            Section("운영"){
                ForEach(prodList, id:\.id){ item in
                    NavigationLink(destination:{
                        SourceDeployDetail(viewModel:viewModel,
                                             selectedBuildInfo: item)
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
                        SourceDeployDetail(viewModel:viewModel,
                                             selectedBuildInfo: item)
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
        SourceDeployListView(viewModel: ViewModel())
}
