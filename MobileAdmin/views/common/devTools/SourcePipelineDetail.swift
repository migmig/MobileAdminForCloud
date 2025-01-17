//
//  SourcePipelineDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/17/25.
//

import SwiftUI

struct SourcePipelineDetail: View {
    @ObservedObject var viewModel:ViewModel
    var selectedPipeline:SourcePipelineInfoProjectList
    @State private var sourcePipelineExecResultResult:SourcePipelineExecResultResult = SourcePipelineExecResultResult()
    @State private var isConfirm:Bool = false
    @State private var isCancel:Bool = false
    var body: some View {
        List{
            Section("파이프라인"){
                HStack{
                    Text("명칭")
                    Spacer()
                    Text(selectedPipeline.name)
                        .font(.subheadline)
                }
            }
            Section("기능"){
                Button("재조회"){
                    Task{
                        let response = await viewModel.fetchSourcePipelineHistoryInfo(selectedPipeline.id)
                        viewModel.sourcePipelineHistoryList = response.result.historyList.sorted(by: {$0.id > $1.id})
                    }
                }
                
                Button(action:{isConfirm = true}){
                    Text("파이프라인 실행하기")
                }
                .confirmationDialog("실행확인", isPresented: $isConfirm) {
                    Button(action:{
                        Task{
                            let response = await viewModel.runSourcePipeline(selectedPipeline.id)
                            sourcePipelineExecResultResult = response.result
                            isConfirm = false
                        }
                    }){
                        Text("실행확인")
                    }
                }
            }
            Section("History"){
                ForEach(viewModel.sourcePipelineHistoryList, id:\.self){ item in
                    VStack {
                        HStack{
                            Image(systemName:"hammer")
                                .foregroundColor(item.status == "success" ? .blue
                                               : item.status == "running" ? .yellow
                                               : .red )
                            Spacer()
                            VStack{
                                HStack{
                                    Spacer()
                                    Text(item.requestId)
                                        .font(.system(size: 11))
                                }
                                HStack{
                                    Text(Util.convertFromDateIntoString( item.begin))
                                        .font(.system(size: 11))
                                    Spacer()
                                    Text(Util.convertFromDateIntoString( item.end))
                                        .font(.system(size: 11))
                                }
                                HStack{
                                    Spacer()
                                    Text(item.status)
                                        .font(.subheadline)
                                        .foregroundColor(item.status == "success" ? .blue
                                                         : item.status == "running" ? .yellow
                                                         : .red )
                                    if item.status == "running" {
                                        Button("cancel"){
                                            isCancel = true
                                            Task{
                                                let response = await viewModel.cancelSourcePipeline(item.projectId,item.id)
//                                                sourcePipelineExecResultResult = response.result
                                            }
                                        }
                                        .buttonStyle(BorderedButtonStyle())
                                        .alert("취소되었습니다.", isPresented: $isCancel){
                                            Button("확인"){
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(selectedPipeline.name)
        .onAppear(){
            Task{
                let response = await viewModel.fetchSourcePipelineHistoryInfo(selectedPipeline.id)
                viewModel.sourcePipelineHistoryList = response.result.historyList.sorted(by: {$0.id > $1.id})
            }
        }
    }
}

#Preview{
    SourcePipelineDetail(viewModel: ViewModel(), selectedPipeline: SourcePipelineInfoProjectList(522,"oauth-authorization-server"))
}
 
