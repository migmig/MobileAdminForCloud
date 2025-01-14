//
//  SourceBuildDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/13/25.
//

import SwiftUI

struct SourceBuildDetail: View {
    @ObservedObject var viewModel:ViewModel
    var selectedProject:SourceBuildProject?
    @State var sourceBuildInfoResult:SourceBuildInfoResult?
    @State var isLoaded = false
        
    var body: some View {
        VStack{
            HStack{
                Button(action:{
                    Task{
                        isLoaded = true
                        sourceBuildInfoResult = await viewModel.fetchSourceBuildInfo(selectedProject?.id ?? 0)?.result
                        isLoaded = false
                    }
                }){
                    Label("Refresh", systemImage:"arrow.clockwise")
                }
                .buttonStyle(.bordered)
                Button(action:{
                    Task{
                        isLoaded = true
                        let res = await viewModel.execSourceBuild(selectedProject?.id ?? 0)
                        if res?.result.buildId != nil {
                            sourceBuildInfoResult = await viewModel.fetchSourceBuildInfo(selectedProject?.id ?? 0)?.result
                        }
                        isLoaded = false
                    }
                }){
                    Label("Build", systemImage:"hammer")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        
            List{
                if isLoaded {
                    HStack{
                        Spacer()
                        ProgressView() // 로딩바
                        Spacer()
                    }
                }else{
                    Section("Info"){
                        InfoRow3(title:"ID"  , value:selectedProject?.id.description)
                        InfoRow3(title:"Name", value:sourceBuildInfoResult?.name)
                        InfoRow3(
                            title:"Description",
                            value:sourceBuildInfoResult?.description
                        )
                    }
                    Section("Source"){
                        InfoRow3(
                            title:"Repository",
                            value:sourceBuildInfoResult?.source?.config?.repository
                        )
                        
                        InfoRow3(
                            title:"branch",
                            value:sourceBuildInfoResult?.source?.config?.branch
                        )
                    }
                    Section("Last Build"){
                        NavigationLink{
                            SourceBuildHistory(projectId: selectedProject?.id ?? 0)
                        } label:{
                            InfoRow3(
                                title:"History ID",
                                value:sourceBuildInfoResult?.lastBuild?.id?.description
                            )
                        }
                        InfoRow3(
                            title:"LastBuildTime",
                            value:Util.convertFromDateIntoString(sourceBuildInfoResult?.lastBuild?.timestamp ?? 0)
                        )
                    }
                    Section("CMD"){
                        InfoRow3(
                            title:"pre",
                            value:sourceBuildInfoResult?.cmd?.pre?.joined(separator: "\n")
                        )
                        InfoRow3(
                            title:"build",
                            value:sourceBuildInfoResult?.cmd?.build?.joined(separator: "\n")
                        )
                        InfoRow3(
                            title:"post",
                            value:sourceBuildInfoResult?.cmd?.post?.joined(separator: "\n")
                        )
                    }
                }
            }
            .onChange(of: selectedProject!.id ){oldvalue,newValue in
                Task{
                    isLoaded = true
                    sourceBuildInfoResult = await viewModel.fetchSourceBuildInfo(newValue)?.result
                    isLoaded = false
                }
            }
            .onAppear(){
                
                    Task{
                        isLoaded = true
                        sourceBuildInfoResult = await viewModel.fetchSourceBuildInfo(selectedProject?.id ?? 0)?.result
                        isLoaded = false
                    }
            }
            #if os(iOS)
            .listStyle(GroupedListStyle())
            #endif
            //.padding()
        }
        .navigationTitle("[\(selectedProject!.id.description)]\(selectedProject!.name)")
    }
}
 
#Preview{
    SourceBuildDetail(viewModel: ViewModel(), selectedProject: (SourceBuildProject(
        3334, "oauth-resource-server", "Permission 1", "Action 1"
    )))
}
