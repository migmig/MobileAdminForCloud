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
                Label("SourceCommit", systemImage: "arrow.up.arrow.down.circle")
                NavigationLink(destination: SourceBuildListViewIOS(viewModel: viewModel)){
                    Label("SourceBuild" , systemImage: "gearshape.2")
                }
                Label("SourceDeploy", systemImage: "arrow.up.circle")
                Label("SourcePipeline", systemImage: "rectangle.connected.to.line.below")
            }
            .navigationTitle("빌드관련")
        }
    }
}

#Preview {
    SourceControlViewForIOS(viewModel: ViewModel() )
}
