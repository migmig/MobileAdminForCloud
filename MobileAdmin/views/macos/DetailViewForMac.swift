import SwiftUI

struct DetailViewForMac: View {
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var nav: NavigationState

    var body: some View {
        detailContent
    }

    @ViewBuilder
    private var detailContent: some View {
        switch nav.selectedSidebarItem {
        case .errerlist:
            ErrorCloudItemView(
                errorCloudItem: nav.selectedErrorItem ?? ErrorCloudItem()
            )

        case .toast:
            ToastView(toastItem: $nav.toast)

        case .goodsInfo:
            GoodsDetailView(goodsinfo: nav.selectedGoods ?? Goodsinfo())

        case .gcpClsList:
            EdcCrseDetailView(
                edcCrseClinfo: nav.selectedEdcCrseCl ?? EdcCrseCl("", "")
            )

        case .codeList:
            CodeDetailView(
                cmmnGroupCodeItem: nav.selectedGroupCode ?? CmmnGroupCodeItem(
                    cmmnGroupCode: "",
                    cmmnGroupCodeNm: "",
                    groupEstbs1Value: "",
                    groupEstbs2Value: "",
                    groupEstbs3Value: "",
                    groupEstbs4Value: "",
                    groupEstbs5Value: "",
                    groupEstbs6Value: "",
                    groupEstbs7Value: "",
                    useAt: ""
                )
            )

        case .closeDeptList:
            CloseDeptDetail(
                closeDetail: nav.selectedCloseDept ?? Detail1(
                    closeempno: "",
                    rmk: "",
                    deptprtnm: "",
                    closegb: "",
                    closetime: "",
                    opentime: "",
                    deptcd: ""
                )
            )

        case .sourceBuild:
            if let sourceBuildProject = nav.selectedBuild {
                SourceBuildDetail(selectedProject: sourceBuildProject)
            } else {
                Text("Select a row to view details.")
            }

        case .sourcePipeline:
            if let sourcePipeline = nav.selectedPipeline {
                SourcePipelineDetail(selectedPipeline: sourcePipeline)
            } else {
                Text("Select a row to view details.")
            }

        case .sourceCommit:
            if let sourceCommit = nav.selectedCommit {
                SourceCommitDetail(selectedSourceCommit: sourceCommit)
            } else {
                Text("Select a row to view details.")
            }

        case .sourceDeploy:
            if let sourceDeploy = nav.selectedDeploy {
                SourceDeployDetail(selectedDeploy: sourceDeploy)
            } else {
                Text("Select a row to view details.")
            }

        default:
            Text(" ")
        }
    }
}

#Preview(
    traits: .fixedLayout(width: 600, height: 3200)
){
    DetailViewForMac()
        .environmentObject(ToastManager())
        .environmentObject(NavigationState())
        .environmentObject(ErrorViewModel())
        .environmentObject(EducationViewModel())
        .environmentObject(CodeViewModel())
        .environmentObject(BuildViewModel())
        .environmentObject(PipelineViewModel())
        .environmentObject(CommitViewModel())
        .environmentObject(DeployViewModel())
        .environmentObject(ToastViewModel())
}
