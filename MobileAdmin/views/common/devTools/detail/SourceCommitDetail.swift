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
    @State var isListLoading:Bool = false
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
#if os(macOS)
.font(.title2)
#endif
            Section("Branch"){
                if isListLoading{
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }else{
                    ForEach(branchList, id: \.self){ branch in
                        HStack{
                            Image(systemName: SlidebarItem.sourceCommit.img)
                                .foregroundColor(.blue)
                            Text(branch)
                                .transition(.blurAndFade)
                        }
                    }
                }
            }
        }
#if os(macOS)
.font(.title2)
#endif
        .onChange(of: selectedSourceCommitInfoRepository.name){_,  newValue in
            Task{
                withAnimation{
                    isListLoading = true
                }
                let sourceCommitBranchInfo = await viewModel.fetchSourceCommitBranchList(selectedSourceCommitInfoRepository.name)
                branchList = sourceCommitBranchInfo.result.branch;
                withAnimation{
                    isListLoading = false
                }
            }
        }
        .onAppear(){
            Task{
                withAnimation{
                    isListLoading = true
                }
                let sourceCommitBranchInfo = await viewModel.fetchSourceCommitBranchList(selectedSourceCommitInfoRepository.name)
                branchList = sourceCommitBranchInfo.result.branch;
                withAnimation{
                    isListLoading = false
                }
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
