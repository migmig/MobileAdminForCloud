import SwiftUI

struct SourceCommitListView: View {
    @EnvironmentObject var commitViewModel: CommitViewModel
    @Binding var selectedCommit: SourceCommitInfoRepository?

    var body: some View {
        List(selection: $selectedCommit) {
            ForEach(commitViewModel.sourceCommitInfoRepository, id: \.id) { item in
                #if os(iOS)
                NavigationLink(destination: SourceCommitDetail(selectedSourceCommit: item)) {
                    HStack {
                        Image(systemName: SlidebarItem.sourceCommit.img)
                            .foregroundColor(AppColor.link)
                        Text(item.name)
                    }
                }
                #endif
                #if os(macOS)
                NavigationLink(value: item) {
                    HStack {
                        Image(systemName: SlidebarItem.sourceCommit.img)
                            .foregroundColor(AppColor.link)
                        Text(item.name)
                    }
                }
                #endif
            }
            #if os(macOS)
            .font(AppFont.sidebarItem)
            #endif
        }
        .navigationTitle("소스커밋목록")
        .onAppear {
            if commitViewModel.sourceCommitInfoRepository.isEmpty {
                Task { await commitViewModel.fetchSourceCommitList() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SourceCommitListView(selectedCommit: .constant(nil))
            .environmentObject(CommitViewModel())
    }
}
