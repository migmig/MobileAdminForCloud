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
        //NavigationStack{
            VStack{
                StageButtonViewCommon(searchText: $searchText)
                List(filteredList){ item in
                    NavigationLink(destination:{
                        SourceBuildDetail(viewModel:viewModel,
                                          selectedProject: item)
                    }){
                        HStack{
                            Image(systemName: item.name.contains("prod") ? "antenna.radiowaves.left.and.right" :"gearshape.2")
                                .foregroundColor(item.name.contains("prod") ? .red : .blue)
                            Text("[\(item.id.description)] \(item.name)")
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
 
