//
//  SourceDeployDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/21/25.
//

import SwiftUI

struct SourceDeployDetail: View {
    @ObservedObject var viewModel:ViewModel
    var selectedDeploy:SourceInfoProjectInfo
    @State private var stageList:[SourceDeployStageInfoProject] = []
    @State private var historyList : [SourceDeployHistoryInfoHistoryList] = []
    @State private var scenarioList : [SourceDeployScenarioInfoProject] = []
    @State private var isConfirm:Bool = false
    @State private var isCancel:Bool = false
    @State var isLoaded = false
    @State var stageId:Int = 0
    @State var scenarioId:Int = 0
    var body: some View {
        List{
            Section("배포"){
                HStack{
                    Text("명칭")
                    Spacer()
                    Text(selectedDeploy.name)
                        .font(.subheadline)
                }
            }
            Section("Stage"){
                Picker("Stage", selection: $stageId){
                    ForEach(stageList, id:\.id){ item in
                        Text(item.name)
                    }
                }
                .onChange(of: stageId){_,newValue in
                    getScenario()
                }
            }
            Section("Scenario"){
                Picker("Scenario", selection: $scenarioId){
                    ForEach(scenarioList, id:\.id){ item in
                        Text(item.name)
                    }
                }
                .onChange(of: stageId){_,newValue in
                    getScenario()
                }
            }
            Section("기능"){
                Button("재조회"){
                    getStage()
                    getHistory()
                }
                Button(action:{isConfirm = true}){
                    Text("배포 실행하기")
                }
                .confirmationDialog("실행확인", isPresented: $isConfirm) {
                    Button(action:{
                        runSourceDeploy()
                        getHistory()
                    }){
                        Text("실행확인")
                    }
                }
            }
            Section("History"){
                if isLoaded {
                    HStack{
                        ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
                    }
                }else{
                    ForEach(historyList  , id:\.id){ item in
                        VStack{
                            HStack{
                                Image(systemName:"hammer")
                                    .foregroundColor(item.status == "success" ? .blue
                                                     : item.status == "inprogress" ? .purple
                                                     : .red )
                                Text(Util.convertFromDateIntoString(item.startTime) )
                                Spacer()
                                VStack{
                                    
                                    HStack{
                                        Spacer()
                                        Text(item.status  )
                                            .foregroundColor(item.status == "success" ? .blue
                                                             : item.status == "inprogress" ? .purple
                                                             : .red )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(selectedDeploy.name)
        .onChange(of: selectedDeploy.id){_, newValue in
            getStage()
            getHistory()
        }
        .onAppear(){
            getStage()
            getHistory()
        }
    }
    func runSourceDeploy(){
        Task{
            withAnimation{
                isLoaded = true
            }
            await viewModel.runSourceDeploy(selectedDeploy.id,stageId,scenarioId)
            isConfirm = false
            
            withAnimation{
                isLoaded = true
            }
        }
    }
    func getStage(){
        Task{
            withAnimation{
                isLoaded = true
            }
            let response = await viewModel.fetchSourceDeployStageInfo(selectedDeploy.id)
            stageList = response.result?.stageList ?? []
            stageList.first.map{
                stageId = $0.id
            }
            getScenario()
            
            withAnimation{
                isLoaded = true
            }
        }
    }
    func getScenario(){
        Task{
            let response = await viewModel.fetchSourceDeployScenarioInfo(selectedDeploy.id, stageId)
            scenarioList = response.result?.scenarioList ?? []
            scenarioList.first.map{
                scenarioId = $0.id
            }
        }
    }
    
    func getHistory(){
        Task{
            withAnimation{
                isLoaded = true
            }
            let response = await viewModel.fetchSourceDeployHistoryInfo(selectedDeploy.id)
            historyList = response.result?.historyList?.sorted(by: {$0.id > $1.id  }) ?? []
            
            withAnimation{
                isLoaded = false
            }
        }
    }
}

#Preview {
    SourceDeployDetail(viewModel: ViewModel(), selectedDeploy: SourceInfoProjectInfo(1138,"oauth-resource-server"))
}
