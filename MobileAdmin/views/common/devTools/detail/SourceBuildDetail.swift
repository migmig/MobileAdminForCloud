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
        switch status {
        case "success":
            return .blue
        case "fail":
            return .red
        case "upload":
            return .purple
        case "canceled":
            return .pink
        default:
            return .gray
        }
    }
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
                        //NavigationLink{
                        //    SourceBuildHistory(viewModel:viewModel,
                        //                       projectId: selectedProject?.id ?? 0)
                        //} label:{
                            InfoRow3(
                                title:"History ID",
                                value:sourceBuildInfoResult?.lastBuild?.id?.description
                            )
                            .lineLimit(1)
                       // }
                        InfoRow3(
                            title:"LastBuildTime",
                            value:Util.convertFromDateIntoString(sourceBuildInfoResult?.lastBuild?.timestamp ?? 0)
                        )
                    }
                }
            
            Section("History"){
                ForEach(sourceBuildHistoryInfoHistory, id: \.self){item in
                    VStack{
                        HStack{
                            Image(systemName:"hammer")
                                .foregroundColor(getBuildColor(status: item.status ?? ""))
                            Spacer()
                            Text(item.userId ?? "")
                                .font(.subheadline)
                        }
                        HStack{
                            Text(Util.convertFromDateIntoString( item.begin ?? 0))
                                .font(.system(size: 11))
                            Spacer()
                            Text(Util.convertFromDateIntoString( item.end ?? 0))
                                .font(.system(size: 11))
                        }
                        HStack{
                            Spacer()
                            Text(item.status ?? "")
                                .font(.subheadline)
                                .foregroundColor(getBuildColor(status: item.status ?? ""))
                        }
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
                getBuildHistory()
            }
            .onAppear(){
                getBuildInfo()
                getBuildHistory()
                
            }
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
