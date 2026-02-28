import SwiftUI

struct ContentListViewForMac: View {
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
        case .errorlist:
            ErrorSidebar(selectedErrorItem: $nav.selectedErrorItem)

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
            EdcClsSidebar(selectedEdcCrseCl: $nav.selectedEdcCrseCl)

        case .codeList:
            GroupCodesSidebar(selectedGroupCode: $nav.selectedGroupCode)

        case .closeDeptList:
            CloseDeptSidebar(list: $nav.closeDeptList,
                             selectedCloseDept: $nav.selectedCloseDept)

        case .sourceCommit:
            SourceCommitListView(selectedCommit: $nav.selectedCommit)

        case .sourceBuild:
            SourceBuildListView(selected: $nav.selectedBuild)

        case .sourceDeploy:
            SourceDeployListView(selectedDeploy: $nav.selectedDeploy)

        case .sourcePipeline:
            SourcePipelineListView(selectedPipeline: $nav.selectedPipeline)

        default:
            Text("알 수 없는 항목입니다.")
        }
    }
}

#Preview {
    ContentListViewForMac()
        .environmentObject(NavigationState())
        .environmentObject(ErrorViewModel())
        .environmentObject(GoodsViewModel())
        .environmentObject(CodeViewModel())
        .environmentObject(EducationViewModel())
        .environmentObject(CloseDeptViewModel())
        .environmentObject(BuildViewModel())
        .environmentObject(PipelineViewModel())
        .environmentObject(CommitViewModel())
        .environmentObject(DeployViewModel())
}
