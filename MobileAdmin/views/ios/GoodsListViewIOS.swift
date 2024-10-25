import SwiftUI

struct GoodsListViewIOS: View {
    @ObservedObject var viewModel:ViewModel
    @ObservedObject var toastManager: ToastManager
    @Binding var goodsItems:[Goodsinfo]
    @State var isLoading:Bool = false
    var body: some View {
        NavigationStack{
            VStack{
                if isLoading {
                    ProgressView(" ")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                List(goodsItems,id:\.self){ item in
                    NavigationLink(value:item){
                        GoodsItemListItem(item)
                    }
                    .navigationTitle("GoodsList")
                }
                .navigationDestination(for: Goodsinfo.self){item in
                    GoodsDetailView(goodsinfo: item)
                }
            }
        }
        .onAppear()
        {
            Task{
                isLoading = true;
                await goodsItems = viewModel.fetchGoods(nil, nil) ?? []
                isLoading = false;
            }
        }
        .refreshable
        {
            Task{
                isLoading = true;
                await goodsItems = viewModel.fetchGoods(nil, nil) ?? []
                isLoading = false;
            }
        }
    }
}

