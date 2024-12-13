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
    @State private var searchText:String = ""
    
    
    var filteredGoods:[Goodsinfo]{
        if searchText.isEmpty{
            return filteredGoodsItems
        }else{
            return filteredGoodsItems.filter{item in
                item.userId?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
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
                                    searchText = ""
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
                        ForEach( filteredGoods,id:\.self){ item in
                            NavigationLink(value:item){
                                GoodsItemListItem(
                                    goodsItem: item,
                                    selectedGoodsCd: selectedGoodsCd
                                )
                            }
                        }
                        .searchable(text: $searchText, placement: .automatic)
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
 
#Preview{
    GoodsListViewIOS(viewModel: .init()
                     ,toastManager: .init()
                     ,goodsItems: .constant([]))
}
