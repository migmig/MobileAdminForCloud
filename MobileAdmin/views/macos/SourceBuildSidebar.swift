//
//  SourceBuildSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/13/25.
//

import SwiftUI

struct SourceBuildSidebar: View {
    @ObservedObject var viewModel:ViewModel
    @Binding var selectedSourceBuildProject:SourceBuildProject?
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
        VStack{ 
            StageButtonViewCommon(searchText: $searchText)
            .padding()
            List(filteredList, selection: $selectedSourceBuildProject){ item in
                NavigationLink(value:item){
                    HStack{
                        Image(systemName:"hammer")
                            .foregroundColor(item.name.contains("prod") ? .red : .blue)
                        Text("[\(item.id.description)] \(item.name)")
                    }
                }
            }
            .onChange(of: selectedSourceBuildProject) {oldvalue, newValue in
                print("Selected project changed to: \(String(describing: newValue))")
            }
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
    
        .navigationTitle("Build Projects")
        
    }
}

#Preview {
    SourceBuildSidebar(viewModel: ViewModel(), selectedSourceBuildProject: .constant(nil))
}
