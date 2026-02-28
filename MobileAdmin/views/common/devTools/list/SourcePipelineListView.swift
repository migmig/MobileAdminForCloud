import SwiftUI

struct SourcePipelineListView: View {
    @EnvironmentObject var pipelineViewModel: PipelineViewModel
    @Binding var selectedPipeline: SourceInfoProjectInfo?

    var prodList: [SourceInfoProjectInfo] {
        pipelineViewModel.sourcePipelineList
            .filter { $0.name.localizedStandardContains("prod") }
            .sorted { $0.name < $1.name }
    }

    var devList: [SourceInfoProjectInfo] {
        pipelineViewModel.sourcePipelineList
            .filter { !$0.name.localizedStandardContains("prod") }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        List(selection: $selectedPipeline) {
            if pipelineViewModel.sourcePipelineList.isEmpty {
                EmptyStateView(systemImage: "rectangle.connected.to.line.below", title: "파이프라인이 없습니다")
                    .listRowBackground(Color.clear)
            }
            Section("운영") {
                ForEach(prodList, id: \.id) { item in
                    #if os(iOS)
                    NavigationLink(destination: SourcePipelineDetail(selectedPipeline: item)) {
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
                    NavigationLink(destination: SourcePipelineDetail(selectedPipeline: item)) {
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
        .navigationTitle("파이프라인")
        .onAppear {
            Task { await pipelineViewModel.fetchSourcePipelineList() }
        }
    }
}

#Preview {
    NavigationStack {
        SourcePipelineListView(selectedPipeline: .constant(nil))
            .environmentObject(PipelineViewModel())
    }
}
