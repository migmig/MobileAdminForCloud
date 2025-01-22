import SwiftUI

struct ContentViewForMac: View {
    @StateObject var viewModel:ViewModel = ViewModel()
    @ObservedObject var toastManager: ToastManager
    @State var selectedErrorItem:ErrorCloudItem? = .init()
    @State var toast:Toast = Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")
    @State var selectedGoods:Goodsinfo? = nil
    @State var edcCrseCl:[EdcCrseCl] = []
    @State var selectedEdcCrseCl:EdcCrseCl? = nil
    @State var groupCodes:CmmnGroupCode? = []
    @State var selectedGroupCode:CmmnGroupCodeItem?
    @State var closeDeptList:[Detail1] = []
    @State var selectedCloseDept:Detail1? = nil
    @State var selectedPipeline:SourceInfoProjectInfo?
    @State var selectedBuild:SourceBuildProject?
    @State var selectedCommit:SourceCommitInfoRepository?
    @State var selectedDeploy:SourceInfoProjectInfo?
//    @State var selectedSourceBuildProject:SourceBuildProject?
//    @State var selectedSourceCommitInfoRepository:SourceCommitInfoRepository?
    
    @State private var selectedSidebarItem: SlidebarItem? = nil
    var body: some View {
        NavigationSplitView{
            SlidebarViewForMac(selection: $selectedSidebarItem)
        }content:{
            ContentListViewForMac(
                viewModel : viewModel,
                selectedSlidebarItem: $selectedSidebarItem,
                toast: $toast,
                selectedGoods: $selectedGoods,
                selectedErrorItem: $selectedErrorItem,
                edcCrseCl: $edcCrseCl,
                selectedEdcCrseCl: $selectedEdcCrseCl,
                groupCodes: $groupCodes,
                selectedGroupCode: $selectedGroupCode,
                closeDeptList: $closeDeptList,
                selectedCloseDept: $selectedCloseDept,
                selectedPipeline: $selectedPipeline,
                selectedBuild: $selectedBuild,
                selectedCommit : $selectedCommit,
                selectedDeploy : $selectedDeploy
//                selectedSourceBuildProject: $selectedSourceBuildProject,
//                selectedSourceCommitInfoRepository: $selectedSourceCommitInfoRepository
            )
        }detail:{
            NavigationStack{
                DetailViewForMac(
                    viewModel : viewModel,
                    toastManager: toastManager,
                    selectedSlidebarItem: $selectedSidebarItem,
                    selectedErrorItem: $selectedErrorItem,
                    toast:$toast,
                    selectedGoods: $selectedGoods,
                    edcCrseCl: $edcCrseCl,
                    selectedEdcCrseCl: $selectedEdcCrseCl,
                    selectedGroupCode: $selectedGroupCode,
                    selectedCloseDept: $selectedCloseDept,
                    selectedPipeline: $selectedPipeline,
                    selectedBuild: $selectedBuild,
                    selectedCommit : $selectedCommit,
                    selectedDeploy : $selectedDeploy
//                    selectedSourceBuildProject: $selectedSourceBuildProject
                )
            }
        }
        
    }
}


#Preview(
    traits: .fixedLayout(width: 1500, height: 1200)
){
    
    ContentViewForMac(
        //viewModel:ViewModel(),
        toastManager: ToastManager()
    )
    .toolbar{
        ToolbarItem{
            Button(action: {
            }) {
                Label("새로고침", systemImage: "arrow.clockwise")
            }
        }
    }
}
