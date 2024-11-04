import SwiftUI

struct ContentViewForMac: View {
    @ObservedObject var viewModel:ViewModel
    @ObservedObject var toastManager: ToastManager
    @State var errorItems:[ErrorCloudItem] = []
    @State var selectedErrorItem:ErrorCloudItem? = nil
    @State var toast:Toast = Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")
    @State var goodsItems:[Goodsinfo] = []
    @State var selectedGoods:Goodsinfo? = nil
    
    @State private var selectedSidebarItem: SlidebarItem? = SlidebarItem.toast
    var body: some View {
        NavigationSplitView{
            SlidebarViewForMac(selection: $selectedSidebarItem)
        }content:{
            ContentListViewForMac(
                viewModel : viewModel,
                selectedSlidebarItem: $selectedSidebarItem,
                toast: $toast,
                goodsinfos: $goodsItems,
                selectedGoods: $selectedGoods,
                selectedErrorItem: $selectedErrorItem,
                errorItems: $errorItems
            )
        }detail:{
            NavigationStack{
                DetailViewForMac(
                    viewModel : viewModel,
                    toastManager: toastManager,
                    selectedSlidebarItem: $selectedSidebarItem,
                    selectedErrorItem: $selectedErrorItem,
                    toast:$toast,
                    selectedGoods: $selectedGoods
                )
            }
        }
        
    }
}

