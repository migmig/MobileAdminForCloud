//
//  SourceBuildListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/14/25.
//

import SwiftUI

struct SourceBuildListViewIOS: View {
    @ObservedObject var viewModel:ViewModel
    @State var selectedSourceBuildProject:SourceBuildProject?
    @State var searchText:String = ""
    var prodList:[SourceBuildProject] {
        viewModel.buildProjects.filter{
            return $0.name.localizedStandardContains("prod")
        }
        .sorted(by: {$0.name < $1.name})
    }
    
    var devList:[SourceBuildProject] {
        viewModel.buildProjects.filter{
            return !$0.name.localizedStandardContains("prod")
        }
        .sorted(by: {$0.name < $1.name})
    }
    var body: some View {
        //NavigationStack{
            VStack{
//                StageButtonViewCommon(searchText: $searchText)
                List{
                    Section("운영"){
                        ForEach(prodList, id:\.id){ item in
                            NavigationLink(destination:{
                                SourceBuildDetail(viewModel:viewModel,
                                                  selectedProject: item)
                            }){
                                HStack{
                                    Image(systemName: item.name.contains("prod") ? Util.getDevTypeImg("prod") : Util.getDevTypeImg("dev"))
                                        .foregroundColor(item.name.contains("prod") ? Util.getDevTypeColor("prod") : Util.getDevTypeColor("dev"))
                                    Text(item.name)
                                }
                            }
                        }
                    }
                    Section("개발"){
                        ForEach(devList, id:\.id){ item in
                            NavigationLink(destination:{
                                SourceBuildDetail(viewModel:viewModel,
                                                  selectedProject: item)
                            }){
                                HStack{
                                    Image(systemName: item.name.contains("prod") ? Util.getDevTypeImg("prod") : Util.getDevTypeImg("dev"))
                                        .foregroundColor(item.name.contains("prod") ? Util.getDevTypeColor("prod") : Util.getDevTypeColor("dev"))
                                    Text(item.name)
                                }
                            }
                        }
                    }
                }
                 
            }
            .navigationTitle("소스빌드목록")
            .onAppear(){
                print("SourceBuildListViewIOS.onAppear()")
                if viewModel.buildProjects.isEmpty {
                    Task{
                        let projects = await viewModel.fetchSourceBuildList()
                        
                        await MainActor.run{
                            viewModel.buildProjects = projects.result.project.sorted(by: {$0.id < $1.id})
                        }
                         
                    }
                }
            }
        //}
    }
}

#Preview{
    SourceBuildListViewIOS(viewModel: ViewModel())
}
