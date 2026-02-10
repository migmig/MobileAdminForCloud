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
                    getHistory()
                }
                
                Button(action:{isConfirm = true}){
                    Text("파이프라인 실행하기")
                }
                .confirmationDialog("실행확인", isPresented: $isConfirm) {
                    Button(action:{
                        runSourcePipeline()
                    }){
                        Text("실행확인")
                    }
                }
            }
            
                Section("History"){if isLoaded {
                    HStack{
                        ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
                           
                    }
                }else{
                    ForEach(viewModel.sourcePipelineHistoryList, id:\.self){ item in
                        VStack {
                            HStack{
                                Image(systemName:"hammer")
                                    .foregroundColor(AppColor.pipelineStatus(item.status))
                                Spacer()
                                VStack{
                                    HStack{
                                        Spacer()
                                        Text(item.requestId)
                                    }
#if os(iOS)
                                    .font(AppFont.timestamp)
#endif
                                    HStack{
                                        Text(Util.convertFromDateIntoString( item.begin))
                                        Spacer()
                                        Text(item.end == 0 ? "" : Util.convertFromDateIntoString( item.end))
                                    }
#if os(iOS)
                                            .font(AppFont.timestamp)
#endif
                                    HStack{
                                        Spacer()
                                        Text(item.status)
                                        #if os(iOS)
                                            .font(AppFont.listSubtitle)
                                        #endif
                                            .foregroundColor(AppColor.pipelineStatus(item.status))
                                        if item.status == "running" {
                                            Button("cancel"){
                                                isCancel = true
                                                Task{
                                                    _ = await viewModel
                                                        .cancelSourcePipeline(
                                                            item.projectId,
                                                            item.id
                                                        )
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
                    }//ForEach
                }//if
            }//Section(history)
        }//List
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
 
