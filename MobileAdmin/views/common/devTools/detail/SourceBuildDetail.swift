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
    @State var sourceBuildHistoryInfoHistory:[SourceBuildHistoryInfoHistory] = []
    @State private var isLoaded:Bool = false
    @State private var isConfirm:Bool = false
    @State private var isCancel:Bool = false
    
    func getBuildColor(status:String) -> Color{
        return AppColor.buildStatus(status)
    }
    var body: some View {
        List{
            Section("프로젝트 정보"){
                InfoRow(title:"ID"  , value:selectedProject?.id.description)
                InfoRow(title:"Name", value:sourceBuildInfoResult?.name)
                InfoRow(title:"Description", value:sourceBuildInfoResult?.description)
            }
            Section("기능"){
                Button(action:{
                    Task{
                        withAnimation { isLoaded = true }
                        sourceBuildInfoResult = await viewModel.fetchSourceBuildInfo(selectedProject?.id ?? 0)?.result
                        withAnimation { isLoaded = false }
                    }
                }){
                    Label("재조회", systemImage: "arrow.clockwise")
                }
                Button(action:{ isConfirm = true }){
                    Label("빌드실행", systemImage: "play.fill")
                }
                .confirmationDialog("실행확인", isPresented: $isConfirm) {
                    Button(action:{ runBuild() }){
                        Text("실행확인")
                    }
                }
            }
            Section("소스"){
                InfoRow(title:"Repository", value:sourceBuildInfoResult?.source?.config?.repository)
                InfoRow(title:"Branch", value:sourceBuildInfoResult?.source?.config?.branch)
            }
            if isLoaded {
                ProgressView()
            } else {
                Section("최근 빌드"){
                    InfoRow(title:"History ID", value:sourceBuildInfoResult?.lastBuild?.id?.description)
                    InfoRow(title:"빌드시각", value:Util.convertFromDateIntoString(sourceBuildInfoResult?.lastBuild?.timestamp ?? 0))
                }
            }

            Section("빌드 이력"){
                ForEach(sourceBuildHistoryInfoHistory, id: \.self){ item in
                    DevHistoryItem(
                        statusColor: getBuildColor(status: item.status ?? ""),
                        status: item.status ?? "",
                        beginTime: Util.convertFromDateIntoString(item.begin ?? 0),
                        endTime: Util.convertFromDateIntoString(item.end ?? 0),
                        subtitle: item.userId ?? ""
                    )
                }
            }
            Section("CMD"){
                InfoRow(title:"pre", value:sourceBuildInfoResult?.cmd?.pre?.joined(separator: "\n"))
                InfoRow(title:"build", value:sourceBuildInfoResult?.cmd?.build?.joined(separator: "\n"))
                InfoRow(title:"post", value:sourceBuildInfoResult?.cmd?.post?.joined(separator: "\n"))
            }
        }
        .navigationTitle(sourceBuildInfoResult?.description ?? selectedProject!.name)
        .onChange(of: selectedProject!.id ){oldvalue,newValue in
            getBuildInfo()
            getBuildHistory()
        }
        .onAppear(){
            getBuildInfo()
            getBuildHistory()
        }
    }
    func getBuildHistory(){
        Task{
            let response = await viewModel.fetchSourceBuildHistory(
                selectedProject?.id ?? 0
            )
            sourceBuildHistoryInfoHistory = Array((response?.result?.history  ?? []).prefix(5))
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
