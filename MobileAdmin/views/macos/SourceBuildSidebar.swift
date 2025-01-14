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
    
    var body: some View {
        List(viewModel.buildProjects, selection: $selectedSourceBuildProject){ item in
            NavigationLink(value:item){
                HStack{
                    Image(systemName:"hammer")
                    Text("[\(item.id.description)] \(item.name)")
                }
            }
        }
        .onChange(of: selectedSourceBuildProject) { newValue in
            print("Selected project changed to: \(String(describing: newValue))")
        }
        .onAppear(){
            if viewModel.buildProjects.isEmpty {
                Task{
                    let projects = await viewModel.fetchSourceBuildList()
                    
                    await MainActor.run{
                        viewModel.buildProjects = projects.result.project
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
