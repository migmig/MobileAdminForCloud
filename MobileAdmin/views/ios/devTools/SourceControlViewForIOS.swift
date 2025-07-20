//
//  SourceControlViewForIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/15/25.
//

import SwiftUI

struct SourceControlViewForIOS: View {
    @EnvironmentObject var viewModel:ViewModel
    @State var selectedPipeline:SourceInfoProjectInfo?
    @State var selectedBuild:SourceBuildProject?
    @State var selectedDeploy:SourceInfoProjectInfo?
    @State var selectedCommit:SourceCommitInfoRepository?
    var body: some View {
        NavigationStack{
            List{
                
                NavigationLink(destination: SourceBuildListView(
                    viewModel: viewModel,
                    selected : $selectedBuild
                )){
                    Label(SlidebarItem.sourceBuild.title , systemImage: SlidebarItem.sourceBuild.img)
                }
                NavigationLink(destination: SourceDeployListView(
                    viewModel: viewModel,
                    selectedDeploy: $selectedDeploy
                )){
                    Label(SlidebarItem.sourceDeploy.title,   systemImage: SlidebarItem.sourceDeploy.img)
                }
                NavigationLink(destination: SourcePipelineListView(
                    viewModel : viewModel,
                    selectedPipeline: $selectedPipeline
                )){
                    Label(SlidebarItem.sourcePipeline.title, systemImage: SlidebarItem.sourcePipeline.img)
                }
            }
            .navigationTitle("빌드관련")
        }
    }
}

#Preview(
) {
    SourceControlViewForIOS().environmentObject(ViewModel() )
}
 
