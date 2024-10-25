import SwiftUI

struct DetailViewForMac: View {
    @ObservedObject var viewModel:ViewModel
    @ObservedObject var toastManager: ToastManager
    @Binding var selectedSlidebarItem:SlidebarItem?
    @Binding var selectedErrorItem : ErrorCloudItem?
    @Binding var toast: Toast?
    @Binding var selectedGoods:Goodsinfo?
    var body: some View {
        if(selectedSlidebarItem == SlidebarItem.errerlist){
            if let entry = selectedErrorItem{
                ErrorCloudItemView(errorCloudItem: entry,toastManager: toastManager)
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
        }
    }
}

