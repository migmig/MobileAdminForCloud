//
//  SourceCommitDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/16/25.
//

import SwiftUI

struct SourceCommitDetail: View {
    @ObservedObject var viewModel:ViewModel
    var selectedSourceCommitInfoRepository:SourceCommitInfoRepository
    @State var branchList:[String] = []
    var body: some View {
        List{
            Section("Repository"){
                HStack{
                    Text("명칭")
                    Spacer()
                    Text(selectedSourceCommitInfoRepository.name)
                        .font(.subheadline)
                } 
            }
            Section("Branch"){
                ForEach(branchList, id: \.self){ branch in
                    HStack{
                        Text(branch)
                    }
                }
            }
        }
        .onAppear(){
            Task{
                let sourceCommitBranchInfo = await viewModel.fetchSourceCommitBranchList(selectedSourceCommitInfoRepository.name)
                branchList = sourceCommitBranchInfo.result.branch;
            }
        }
        .navigationTitle(selectedSourceCommitInfoRepository.name)
    }
}
 
#Preview{
    SourceCommitDetail(viewModel: ViewModel(),
                       selectedSourceCommitInfoRepository: SourceCommitInfoRepository(
                        id: 11,
                        name: "back-end-git",
                        permission: "permission",
                        actionName: "actionName"
                       ))
}
