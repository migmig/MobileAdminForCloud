import SwiftUI

struct SourceDeployListView: View {
    @EnvironmentObject var deployViewModel: DeployViewModel
    @Binding var selectedDeploy: SourceInfoProjectInfo?

    var prodList: [SourceInfoProjectInfo] {
        deployViewModel.sourceDeployList
            .filter { $0.name.localizedStandardContains("prod") }
            .sorted { $0.name < $1.name }
    }

    var devList: [SourceInfoProjectInfo] {
        deployViewModel.sourceDeployList
            .filter { !$0.name.localizedStandardContains("prod") }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        List(selection: $selectedDeploy) {
            if deployViewModel.sourceDeployList.isEmpty {
                EmptyStateView(systemImage: "arrow.up.circle", title: "배포 프로젝트가 없습니다")
                    .listRowBackground(Color.clear)
            }
            Section("운영") {
                ForEach(prodList, id: \.id) { item in
                    #if os(iOS)
                    NavigationLink(destination: SourceDeployDetail(selectedDeploy: item)) {
                        SourcelineListSubView(itemNm: item.name)
                    }
                    #endif
                    #if os(macOS)
                    NavigationLink(value: item) {
                        SourcelineListSubView(itemNm: item.name)
                    }
                    #endif
                }
            }
            #if os(macOS)
            .font(AppFont.sidebarItem)
            #endif
            Section("개발") {
                ForEach(devList, id: \.id) { item in
                    #if os(iOS)
                    NavigationLink(destination: SourceDeployDetail(selectedDeploy: item)) {
                        SourcelineListSubView(itemNm: item.name)
                    }
                    #endif
                    #if os(macOS)
                    NavigationLink(value: item) {
                        SourcelineListSubView(itemNm: item.name)
                    }
                    #endif
                }
            }
            #if os(macOS)
            .font(AppFont.sidebarItem)
            #endif
        }
        .navigationTitle("소스배포")
        .onAppear {
            Task { await deployViewModel.fetchSourceDeployList() }
        }
    }
}

#Preview {
    NavigationStack {
        SourceDeployListView(selectedDeploy: .constant(nil))
            .environmentObject(DeployViewModel())
    }
}
