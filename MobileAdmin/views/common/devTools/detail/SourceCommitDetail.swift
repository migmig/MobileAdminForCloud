//
//  SourceCommitDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/16/25.
//

import SwiftUI

struct SourceCommitDetail: View {
    @ObservedObject var viewModel:ViewModel
    var selectedSourceCommit:SourceCommitInfoRepository
    @State var branchList:[String] = []
    @State var isListLoading:Bool = false
    var body: some View {
        List{
            Section("Repository"){
                InfoRow(title: "명칭", value: selectedSourceCommit.name)
            }
#if os(macOS)
.font(AppFont.sidebarItem)
#endif
            Section("Branch (\(branchList.count))"){
                if isListLoading{
                    ProgressView()
                }else{
                    ForEach(branchList, id: \.self){ branch in
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(AppColor.link)
                                .font(AppFont.caption)
                            Text(branch)
                                .font(AppFont.listSubtitle)
                                .transition(.blurAndFade)
                        }
                        .padding(.vertical, AppSpacing.xxs)
                    }
                }
            }
        }
#if os(macOS)
.font(AppFont.sidebarItem)
#endif
        .onChange(of: selectedSourceCommit.name){_,  newValue in
            Task{
                withAnimation{
                    isListLoading = true
                }
                let sourceCommitBranchInfo = await viewModel.fetchSourceCommitBranchList(selectedSourceCommit.name)
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
                let sourceCommitBranchInfo = await viewModel.fetchSourceCommitBranchList(selectedSourceCommit.name)
                branchList = sourceCommitBranchInfo.result.branch;
                withAnimation{
                    isListLoading = false
                }
            }
        }
        .navigationTitle(selectedSourceCommit.name)
    }
}
 
#Preview{
    SourceCommitDetail(viewModel: ViewModel(),
                       selectedSourceCommit: SourceCommitInfoRepository(
                        id: 11,
                        name: "back-end-git",
                        permission: "permission",
                        actionName: "actionName"
                       ))
}
