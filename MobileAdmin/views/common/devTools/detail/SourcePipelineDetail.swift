//
//  SourcePipelineDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/17/25.
//

import SwiftUI

struct SourcePipelineDetail: View {
    @ObservedObject var viewModel:ViewModel
    var selectedPipeline:SourceInfoProjectInfo
    @State private var sourcePipelineExecResultResult:SourcePipelineExecResultResult = SourcePipelineExecResultResult()
    @State private var isConfirm:Bool = false
    @State private var isCancel:Bool = false
    @State var isLoaded = false
    var body: some View {
        List{
            Section("파이프라인 프로젝트"){
                InfoRow(title: "명칭", value: selectedPipeline.name)
            }
            Section("기능"){
                Button {
                    getHistory()
                } label: {
                    Label("재조회", systemImage: "arrow.clockwise")
                }

                Button(action:{ isConfirm = true }){
                    Label("파이프라인 실행하기", systemImage: "play.fill")
                }
                .confirmationDialog("실행확인", isPresented: $isConfirm) {
                    Button(action:{ runSourcePipeline() }){
                        Text("실행확인")
                    }
                }
            }

            Section("파이프라인 이력"){
                if isLoaded {
                    ProgressView()
                } else {
                    ForEach(viewModel.sourcePipelineHistoryList, id:\.self){ item in
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            DevHistoryItem(
                                statusColor: AppColor.pipelineStatus(item.status),
                                status: item.status,
                                beginTime: Util.convertFromDateIntoString(item.begin),
                                endTime: item.end == 0 ? "" : Util.convertFromDateIntoString(item.end),
                                subtitle: item.requestId
                            )

                            if item.status == "running" {
                                Button {
                                    isCancel = true
                                    Task{
                                        _ = await viewModel.cancelSourcePipeline(item.projectId, item.id)
                                    }
                                } label: {
                                    Label("Cancel", systemImage: "xmark.circle")
                                        .font(AppFont.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .alert("취소되었습니다.", isPresented: $isCancel){
                                    Button("확인"){}
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(selectedPipeline.name)
        .onChange(of: selectedPipeline.id){_, newValue in
            getHistory()
        }
        .onAppear(){
            getHistory()
        }
    }
    func runSourcePipeline(){
        Task{
            let response = await viewModel.runSourcePipeline(selectedPipeline.id)
            sourcePipelineExecResultResult = response.result
            isConfirm = false
        }
    }
    func getHistory(){
        Task{
            withAnimation{
                isLoaded = true
            }
            let response = await viewModel.fetchSourcePipelineHistoryInfo(selectedPipeline.id)
            viewModel.sourcePipelineHistoryList = Array((response.result.historyList.sorted(by: {$0.id > $1.id})).prefix(5))
            
            withAnimation{
                isLoaded = false
            }
        }
    }
}

#Preview{
    SourcePipelineDetail(viewModel: ViewModel(), selectedPipeline: SourceInfoProjectInfo(522,"oauth-authorization-server"))
}
 
