import SwiftUI

struct GoodsListViewIOS: View {
    @ObservedObject var viewModel:ViewModel
    @ObservedObject var toastManager: ToastManager
    @Binding var goodsItems:[Goodsinfo]
    @State private var filteredGoodsItems:[Goodsinfo] = []
    @State private var isLoading:Bool = false
    @State private var dateFrom:Date = Date()
    @State private var dateTo:Date = Date()
    @State private var arrGoods:[String] = []
    @State private var selectedGoodsCd:[String] = []
     
    var body: some View {
        NavigationStack{
            VStack{
                List{
                    Section{
                        SearchArea(dateFrom: $dateFrom,
                                   dateTo: $dateTo,
                                   isLoading: $isLoading,
                                   clearAction:{
                                        selectedGoodsCd.removeAll()
                                    }){
                            goodsItems = await viewModel
                                .fetchGoods(dateFrom, dateTo) ?? []
                            let arr  = Set(goodsItems.flatMap{item in
                                item.goods.map{$0.goodsCd}
                            })
                            arrGoods = Array(arr)
                            filteredGoodsItems = goodsItems
                        }
                        
                        FilteredGoodsItem(
                            arrGoods: $arrGoods,
                            selectedGoodsCd: $selectedGoodsCd,
                            filteredGoodsItems: $filteredGoodsItems,
                            goodsItems: $goodsItems
                        )
                        
                        if selectedGoodsCd.count > 0{
                            HStack{
                                Text("count:\(filteredGoodsItems.count)")
                                Button("Clear"){
                                    selectedGoodsCd = []
                                    filteredGoodsItems = goodsItems
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    if isLoading {
                        ProgressView(" ")
                            .progressViewStyle(CircularProgressViewStyle())
                    }else{
                        ForEach( filteredGoodsItems,id:\.self){ item in
                            NavigationLink(value:item){
                                GoodsItemListItem(
                                    goodsItem: item,
                                    selectedGoodsCd: selectedGoodsCd
                                )
                            }
                        }
                    }
                }
                .navigationTitle("GoodsList")
                .navigationDestination(for: Goodsinfo.self){item in
                    GoodsDetailView(goodsinfo: item)
                }
            }
        }
        .onAppear()
        {
            Task{
                isLoading = true;
                // await goodsItems = viewModel.fetchGoods(nil, nil) ?? []
                isLoading = false;
            }
        }
        .refreshable
        {
            Task{
                isLoading = true;
               // await goodsItems = viewModel.fetchGoods(nil, nil) ?? []
                isLoading = false;
            }
        }
    }
}
 
