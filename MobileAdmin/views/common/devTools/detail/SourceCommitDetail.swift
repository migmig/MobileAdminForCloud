import SwiftUI

struct SourceCommitDetail: View {
    @EnvironmentObject var commitViewModel: CommitViewModel
    var selectedSourceCommit: SourceCommitInfoRepository
    @State var branchList: [String] = []
    @State var isListLoading: Bool = false

    var body: some View {
        List {
            Section("Repository") {
                InfoRow(title: "명칭", value: selectedSourceCommit.name)
            }
            #if os(macOS)
            .font(AppFont.sidebarItem)
            #endif
            Section("Branch (\(branchList.count))") {
                if isListLoading {
                    ProgressView()
                } else {
                    ForEach(branchList, id: \.self) { branch in
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
        .onChange(of: selectedSourceCommit.name) { _, _ in fetchBranches() }
        .onAppear { fetchBranches() }
        .navigationTitle(selectedSourceCommit.name)
    }

    private func fetchBranches() {
        Task {
            withAnimation { isListLoading = true }
            let info = await commitViewModel.fetchSourceCommitBranchList(selectedSourceCommit.name)
            branchList = info.result.branch
            withAnimation { isListLoading = false }
        }
    }
}

#Preview {
    SourceCommitDetail(selectedSourceCommit: SourceCommitInfoRepository(
        id: 11, name: "back-end-git", permission: "permission", actionName: "actionName"
    ))
    .environmentObject(CommitViewModel())
}
