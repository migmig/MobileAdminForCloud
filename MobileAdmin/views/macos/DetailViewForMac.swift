import SwiftUI

struct DetailViewForMac: View {
    @ObservedObject var viewModel:ViewModel
    @ObservedObject var toastManager: ToastManager
    @Binding var selectedSlidebarItem:SlidebarItem?
    @Binding var selectedErrorItem : ErrorCloudItem?
    @Binding var toast: Toast
    @Binding var selectedGoods : Goodsinfo?
    @Binding var edcCrseCl : [EdcCrseCl]
    @Binding var selectedEdcCrseCl : EdcCrseCl?
    @Binding var selectedGroupCode: CmmnGroupCodeItem?
    @Binding var selectedCloseDept: Detail1?
    @Binding var selectedSourceBuildProject: SourceBuildProject?
     
    
    var body: some View {
        if(selectedSlidebarItem == SlidebarItem.errerlist){
            if let entry = selectedErrorItem{
                ErrorCloudItemView(
                    errorCloudItem: entry,
                    toastManager: toastManager
                )
            }else{
                Text("Select a row to view details.")
            }
        }else if(selectedSlidebarItem == SlidebarItem.toast){
            ToastView(
                viewModel: viewModel,
                toastManager: toastManager,
                toastItem: $toast)
        }else if(selectedSlidebarItem == SlidebarItem.goodsInfo){
            if let entry = selectedGoods{
                GoodsDetailView(goodsinfo: entry)
            }else{
                Text("Select a row to view details.")
            }
        }else if(selectedSlidebarItem == SlidebarItem.gcpClsList){
            if let entry = selectedEdcCrseCl{
                EdcCrseDetailView(
                    viewModel: viewModel,
                    edcCrseClinfo:entry
                )
            }else{
                Text("Select a row to view details.")
            }
        }else if(selectedSlidebarItem == SlidebarItem.codeList){
            if let cmmnGroupCodeItem = selectedGroupCode{
                CodeDetailView(
                    viewModel: viewModel,
                    cmmnGroupCodeItem: cmmnGroupCodeItem)
                
            }else{
                Text("Select a row to view details.")
            }
        }else if(selectedSlidebarItem == SlidebarItem.closeDeptList){
            if let closeDeptDetail = selectedCloseDept{
                CloseDeptDetail(
                    closeDetail: closeDeptDetail)
                
            }else{
                Text("Select a row to view details.")
            }
        }else if(selectedSlidebarItem == SlidebarItem.sourceBuild){
            if let sourceBuildProject = selectedSourceBuildProject{
                SourceBuildDetail(viewModel : viewModel,
                                  selectedProject : sourceBuildProject)
            }else{
                Text("Select a row to view details.")
            }
            
        }else{
            Text(" ")
        }
    }
}

#Preview(
    traits: .fixedLayout(width: 600, height: 3200)
){
    DetailViewForMac(
        viewModel: ViewModel(),
        toastManager: ToastManager(),
        selectedSlidebarItem: .constant(SlidebarItem.sourceBuild),
        selectedErrorItem: .constant(nil),
        toast: .constant(Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")),
        selectedGoods: .constant(nil),
        edcCrseCl: .constant(
            Array(repeating: EdcCrseCl(
                "강의제목",
                "강의내용 길게길게길게 "
            ), count: 30)),
        selectedEdcCrseCl: .constant(EdcCrseCl(
            "강의제목",
            "강의내용 길게길게길게 "
        ))
        ,selectedGroupCode: .constant(CmmnGroupCodeItem(
            cmmnGroupCode: "그룹코드",
            cmmnGroupCodeNm: "그룹코드명",
            groupEstbs1Value: "그룹코드설명",
            groupEstbs2Value: "사용여부",
            groupEstbs3Value: "등록자",
            groupEstbs4Value: "등록일",
            groupEstbs5Value: "수정자",
            groupEstbs6Value: "수정일",
            groupEstbs7Value: "수정일",
            useAt:"Y"
            )
        ), selectedCloseDept: .constant(
                Detail1(
                    closeempno: "",
                    rmk: "",
                    deptprtnm: "",
                    closegb: "",
                    closetime: "",
                    opentime: "",
                    deptcd: ""
                )
        ),selectedSourceBuildProject:.constant(nil)
    )
}
