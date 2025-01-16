//
//  SourceControlViewForIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/15/25.
//

import SwiftUI

struct SourceControlViewForIOS: View {
    @StateObject var viewModel:ViewModel = ViewModel()
    var body: some View {
        NavigationStack{
            List{
                Label(SlidebarItem.sourceCommit.title, systemImage: SlidebarItem.sourceCommit.img)
                NavigationLink(destination: SourceBuildListViewIOS(viewModel: viewModel)){
                    Label(SlidebarItem.sourceBuild.title , systemImage: SlidebarItem.sourceBuild.img)
                }
                Label(SlidebarItem.sourceDeploy.title,   systemImage: SlidebarItem.sourceDeploy.img)
                Label(SlidebarItem.sourcePipeline.title, systemImage: SlidebarItem.sourcePipeline.img)
            }
            .navigationTitle("빌드관련")
        }
    }
}

#Preview(
) {
    SourceControlViewForIOS(viewModel: ViewModel() )
}
