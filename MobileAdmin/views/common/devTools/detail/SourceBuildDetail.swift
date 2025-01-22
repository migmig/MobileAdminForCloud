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
    @State private var sourceBuildInfoResult:SourceBuildInfoResult?
    @State private var isLoaded:Bool = false
    @State private var isConfirm:Bool = false
    @State private var isCancel:Bool = false
        
    var body: some View {
        List{
            Section("Info"){
                InfoRow3(title:"ID"  , value:selectedProject?.id.description)
                InfoRow3(title:"Name", value:sourceBuildInfoResult?.name)
                InfoRow3(
                    title:"Description",
                    value:sourceBuildInfoResult?.description
                )
            }
            Section("기능"){
                Button(action:{
                    print("Refresh")
                    Task{
                        withAnimation{
                            isLoaded = true
                        }
                        sourceBuildInfoResult = await viewModel.fetchSourceBuildInfo(selectedProject?.id ?? 0)?.result
                        withAnimation{
                            isLoaded = false
                        }
                    }
                }){
                    Text("재조회")
                }
                Button(action:{
                    isConfirm = true
                }){
                    Text("빌드실행")
                }
                .confirmationDialog("실행확인", isPresented: $isConfirm) {
                    Button(action:{
                        runBuild()
                    }){
                        Text("실행확인")
                    }
                }
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
            if isLoaded {
               // HStack{
                    ProgressView()//.progressViewStyle(CircularProgressViewStyle())
               // }
            }else{
                Section("Last Build"){
                    NavigationLink{
                        SourceBuildHistory(viewModel:viewModel,
                                           projectId: selectedProject?.id ?? 0)
                    } label:{
                            InfoRow3(
                                title:"History ID",
                                value:sourceBuildInfoResult?.lastBuild?.id?.description
                            )
                            .lineLimit(1)
                    }
                    InfoRow3(
                        title:"LastBuildTime",
                        value:Util.convertFromDateIntoString(sourceBuildInfoResult?.lastBuild?.timestamp ?? 0)
                    )
                }
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
        .navigationTitle(sourceBuildInfoResult?.description ?? selectedProject!.name)
        .onChange(of: selectedProject!.id ){oldvalue,newValue in
            getBuildInfo()
        }
        .onAppear(){
            getBuildInfo()
               
        }
    }
    func getBuildInfo(){
        Task{
            withAnimation{
                isLoaded = true
            }
            sourceBuildInfoResult = await viewModel.fetchSourceBuildInfo(selectedProject?.id ?? 0)?.result
            
            withAnimation{
                isLoaded = false
            }
        }
    }
    func runBuild(){
        Task{
            withAnimation{
                isLoaded = true
            }
            let res = await viewModel.execSourceBuild(selectedProject?.id ?? 0)
            if res?.result.buildId != nil {
                sourceBuildInfoResult = await viewModel.fetchSourceBuildInfo(selectedProject?.id ?? 0)?.result
            }
            withAnimation{
                isLoaded = false
            }
        }
    }
}
 
#Preview{
    NavigationStack{
        SourceBuildDetail(viewModel: ViewModel(), selectedProject: (SourceBuildProject(
            3334, "oauth-resource-server", "Permission 1", "Action 1"
        )))
    }
}
