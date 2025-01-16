import SwiftUI

struct ContentViewForMac: View {
    //@ObservedObject var viewModel:ViewModel
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
    @State var selectedSourceBuildProject:SourceBuildProject?
    
    @State private var selectedSidebarItem: SlidebarItem? = nil
    var body: some View {
        NavigationSplitView{
            SlidebarViewForMac(selection: $selectedSidebarItem)
        }content:{
            ContentListViewForMac(
               // viewModel : viewModel,
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
                selectedSourceBuildProject: $selectedSourceBuildProject
            )
        }detail:{
            NavigationStack{
                DetailViewForMac(
                   // viewModel : viewModel,
                    toastManager: toastManager,
                    selectedSlidebarItem: $selectedSidebarItem,
                    selectedErrorItem: $selectedErrorItem,
                    toast:$toast,
                    selectedGoods: $selectedGoods,
                    edcCrseCl: $edcCrseCl,
                    selectedEdcCrseCl: $selectedEdcCrseCl,
                    selectedGroupCode: $selectedGroupCode,
                    selectedCloseDept: $selectedCloseDept,
                    selectedSourceBuildProject: $selectedSourceBuildProject
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
