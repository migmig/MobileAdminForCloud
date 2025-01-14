//
//  SourceBuildListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/14/25.
//

import SwiftUI

struct SourceBuildListViewIOS: View {
    @ObservedObject var viewModel:ViewModel
    @ObservedObject var toastManager:ToastManager
    @State var selectedSourceBuildProject:SourceBuildProject?
    @State var searchText:String = ""
    var filteredList:[SourceBuildProject] {
        searchText.isEmpty ? viewModel.buildProjects :
        viewModel.buildProjects.filter{
            if searchText == "prod" {
                return $0.name.localizedStandardContains("prod")
            } else if searchText == "dev" {
                return !$0.name.localizedStandardContains("prod")
            } else {
                return true
            }
        }
    }
    var body: some View {
        NavigationStack{
            VStack{
                StageButtonViewCommon(searchText: $searchText)
                List(filteredList){ item in
                    NavigationLink(value:item){
                        HStack{
                            Image(systemName:"hammer")
                                .foregroundColor(item.name.contains("prod") ? .red : .blue)
                            Text("[\(item.id.description)] \(item.name)")
                        }
                    }
                }
                .navigationDestination(for: SourceBuildProject.self){item in
                    SourceBuildDetail(viewModel:viewModel,
                                      selectedProject: item)
                }
            }
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
}

#Preview {
    SourceBuildListViewIOS(
        viewModel: ViewModel(),
        toastManager: ToastManager()
    )
}
