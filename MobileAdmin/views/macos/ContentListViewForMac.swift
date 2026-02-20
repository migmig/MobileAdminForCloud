import SwiftUI

struct ContentListViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState
    @State private var isLoading: Bool = false

    var body: some View {
        Group {
            if let selectedItem = nav.selectedSidebarItem {
                makeSidebar(for: selectedItem)
            } else {
                Text("선택된 항목이 없습니다.")
            }
        }
    }

    @ViewBuilder
    private func makeSidebar(for item: SlidebarItem) -> some View {
        switch item {
        case .errerlist:
            ErrorSidebar(viewModel: viewModel,
                         selectedErrorItem: $nav.selectedErrorItem)

        case .toast:
            List {
                if isLoading {
                    ProgressView("로딩 중...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                NavigationLink(value: nav.toast) {
                    Text("토스트조회")
                }
            }

        case .goodsInfo:
            GoodsSidebar(selectedGoods: $nav.selectedGoods)

        case .gcpClsList:
            EdcClsSidebar(viewModel: viewModel,
                          edcCrseCl: $nav.edcCrseCl,
                          selectedEdcCrseCl: $nav.selectedEdcCrseCl)

        case .codeList:
            GroupCodesSidebar(viewModel: viewModel,
                              groupCodes: $nav.groupCodes,
                              selectedGroupCode: $nav.selectedGroupCode)

        case .closeDeptList:
            CloseDeptSidebar(viewModel: viewModel,
                             list: $nav.closeDeptList,
                             selectedCloseDept: $nav.selectedCloseDept)

        case .sourceCommit:
            SourceCommitListView(
                viewModel: viewModel,
                selectedCommit: $nav.selectedCommit
            )

        case .sourceBuild:
            SourceBuildListView(
                viewModel: viewModel,
                selected: $nav.selectedBuild
            )

        case .sourceDeploy:
            SourceDeployListView(
                viewModel: viewModel,
                selectedDeploy: $nav.selectedDeploy
            )

        case .sourcePipeline:
            SourcePipelineListView(
                viewModel: viewModel,
                selectedPipeline: $nav.selectedPipeline
            )

        default:
            Text("알 수 없는 항목입니다.")
        }
    }
}

#Preview {
    ContentListViewForMac()
        .environmentObject(ViewModel())
        .environmentObject(NavigationState())
}
