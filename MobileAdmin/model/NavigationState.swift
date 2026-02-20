import SwiftUI

/// macOS 3-column 레이아웃의 네비게이션 상태를 통합 관리
/// ContentViewForMac → ContentListViewForMac, DetailViewForMac 간의 Prop Drilling 제거
class NavigationState: ObservableObject {
    @Published var selectedSidebarItem: SlidebarItem?
    @Published var selectedErrorItem: ErrorCloudItem? = .init()
    @Published var toast: Toast = Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")
    @Published var selectedGoods: Goodsinfo?
    @Published var edcCrseCl: [EdcCrseCl] = []
    @Published var selectedEdcCrseCl: EdcCrseCl?
    @Published var groupCodes: [CmmnGroupCodeItem]?
    @Published var selectedGroupCode: CmmnGroupCodeItem?
    @Published var closeDeptList: [Detail1] = []
    @Published var selectedCloseDept: Detail1?
    @Published var selectedPipeline: SourceInfoProjectInfo?
    @Published var selectedBuild: SourceBuildProject?
    @Published var selectedCommit: SourceCommitInfoRepository?
    @Published var selectedDeploy: SourceInfoProjectInfo?
}
