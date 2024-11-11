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
        }else{
            Text(" ")
        }
    }
}

#Preview{
    DetailViewForMac(
        viewModel: ViewModel(),
        toastManager: ToastManager(),
        selectedSlidebarItem: .constant(SlidebarItem.gcpClsList),
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
    )
}
