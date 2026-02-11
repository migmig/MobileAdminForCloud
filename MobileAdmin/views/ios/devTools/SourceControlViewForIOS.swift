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

    private var menuItems: [(SlidebarItem, String, Color, AnyView)] {
        [
            (.sourceBuild,    "빌드 프로젝트를 관리합니다",   .blue,
             AnyView(SourceBuildListView(viewModel: viewModel, selected: $selectedBuild))),
            (.sourceDeploy,   "배포 스테이지를 관리합니다",   .green,
             AnyView(SourceDeployListView(viewModel: viewModel, selectedDeploy: $selectedDeploy))),
            (.sourcePipeline, "파이프라인 이력을 조회합니다", .purple,
             AnyView(SourcePipelineListView(viewModel: viewModel, selectedPipeline: $selectedPipeline))),
        ]
    }

    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(menuItems, id: \.0) { item, desc, color, dest in
                        NavigationLink(destination: dest) {
                            HomeMenuCard(
                                title: item.title,
                                systemImage: item.img,
                                description: desc,
                                accentColor: color
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .groupedBackground()
            .navigationTitle("개발도구")
        }
    }
}

#Preview(
) {
    SourceControlViewForIOS().environmentObject(ViewModel() )
}
 
