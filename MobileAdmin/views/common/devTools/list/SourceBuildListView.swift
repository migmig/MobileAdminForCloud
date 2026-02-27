import SwiftUI

struct SourceBuildListView: View {
    @EnvironmentObject var buildViewModel: BuildViewModel
    @Binding var selected: SourceBuildProject?

    var prodList: [SourceBuildProject] {
        buildViewModel.buildProjects
            .filter { $0.name.localizedStandardContains("prod") }
            .sorted { $0.name < $1.name }
    }

    var devList: [SourceBuildProject] {
        buildViewModel.buildProjects
            .filter { !$0.name.localizedStandardContains("prod") }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        List(selection: $selected) {
            if buildViewModel.buildProjects.isEmpty {
                EmptyStateView(systemImage: "hammer", title: "빌드 프로젝트가 없습니다")
                    .listRowBackground(Color.clear)
            }
            Section("운영") {
                ForEach(prodList, id: \.id) { item in
                    #if os(iOS)
                    NavigationLink(destination: SourceBuildDetail(selectedProject: item)) {
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
                    NavigationLink(destination: SourceBuildDetail(selectedProject: item)) {
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
        .navigationTitle("소스빌드목록")
        .onAppear {
            if buildViewModel.buildProjects.isEmpty {
                Task { await buildViewModel.fetchSourceBuildList() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SourceBuildListView(selected: .constant(nil))
            .environmentObject(BuildViewModel())
    }
}
