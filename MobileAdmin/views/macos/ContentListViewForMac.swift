import SwiftUI

struct ContentListViewForMac: View {
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @Binding var selectedSlidebarItem:SlidebarItem?
    @Binding var toast:Toast
    @Binding var goodsinfos:[Goodsinfo]
    @Binding var selectedGoods:Goodsinfo?
    @Binding var selectedErrorItem:ErrorCloudItem?
    @Binding var errorItems:[ErrorCloudItem]
    @State private var isLoading:Bool = false
    @State private var searchText = ""
    
    
    var formatDate:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 날짜 형식을 설정
        return formatter.string(from: Date()) // 포맷된 문자열 반환
    }
      
    
    var body: some View {
        
        if(selectedSlidebarItem == SlidebarItem.errerlist){
            ErrorSidebar(errorItems:$errorItems,
                         selectedErrorItem :$selectedErrorItem)
        }else if(selectedSlidebarItem == SlidebarItem.toast){
            List{
                NavigationLink(value:toast){
                    Text(toast.noticeHder )
                }
            }.onAppear()
            {
                Task{
                    isLoading = true;
                    await toast = viewModel.fetchToasts()
                    isLoading = false;
                }
            }
        }else if(selectedSlidebarItem == SlidebarItem.goodsInfo){
            List(goodsinfos,selection:$selectedGoods){ item in
                NavigationLink(value:item){
                    GoodsItemListItem(item)
                }
            }.onAppear()
            {
                Task{
                    isLoading = true;
                    await goodsinfos = viewModel.fetchGoods(nil,nil) ?? []
                    isLoading = false;
                }
            }
        }
    }
}
 
