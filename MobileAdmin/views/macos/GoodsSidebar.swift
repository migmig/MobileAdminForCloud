//
//  GoodsSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/5/24.
//

import SwiftUI

struct GoodsSidebar: View {
    @ObservedObject var viewModel:ViewModel = ViewModel()
//    @Binding var goodsItems:[Goodsinfo]
    @Binding var selectedGoods:Goodsinfo?
    @State   var isLoading:Bool = false
    @State var dateFrom:Date = Date()
    @State var dateTo:Date = Date()
    @State private var arrGoods:[String] = []
    @State private var selectedGoodsCd:[String] = []
    @State private var filteredGoodsItems:[Goodsinfo] = []
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
        SearchArea(dateFrom: $dateFrom,
                   dateTo: $dateTo,
                   isLoading: $isLoading,
                   clearAction:{
                        selectedGoodsCd.removeAll()
            
                    }
        ){
            viewModel.goodsItems = await viewModel.fetchGoods(dateFrom, dateTo) ?? []
            let arr  = Set(viewModel.goodsItems.flatMap{item in
                item.goods.map{$0.goodsCd}
            })
            arrGoods = Array(arr)
            if searchText.isEmpty {
                filteredGoodsItems = viewModel.goodsItems
            }else{
                filteredGoodsItems = viewModel.goodsItems.filter{item in
                    item.userId?.localizedCaseInsensitiveContains(searchText) == true
                }
            }
        }
        
        if isLoading {
            ProgressView(" ")
                .progressViewStyle(CircularProgressViewStyle())
        }
        
        FilteredGoodsItem(
            arrGoods: $arrGoods,
            selectedGoodsCd: $selectedGoodsCd,
            filteredGoodsItems: $filteredGoodsItems,
            goodsItems: $viewModel.goodsItems
        )
        .padding(.horizontal)
        
        if selectedGoodsCd.count > 0{
            HStack{
                Text("count:\(filteredGoodsItems.count)")
                Button("Clear"){
                    selectedGoodsCd = []
                    if searchText.isEmpty {
                        filteredGoodsItems = viewModel.goodsItems
                    }else{
                        filteredGoodsItems = viewModel.goodsItems.filter{item in
                            item.userId?.localizedCaseInsensitiveContains(searchText) == true
                        }
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        Section{
            List(filteredGoods,selection:$selectedGoods){ item in
                NavigationLink(value:item){
                    GoodsItemListItem(
                        goodsItem: item
                        , selectedGoodsCd: selectedGoodsCd
                    )
                }
            }
        }
        .searchable(text: $searchText, placement: .automatic)
        .onAppear()
        {
            Task{
                isLoading = true;
                // await goodsItems = viewModel.fetchGoods(dateFrom,dateTo) ?? []
                isLoading = false;
            }
        }
        .navigationTitle("상품조회이력")
        #if os(macOS)
        .navigationSubtitle("  \(filteredGoodsItems.count)개")
        #endif
    }
}

#Preview {
    GoodsSidebar(
        selectedGoods: .constant(Goodsinfo("UT000000", "20111104"))
    )
}
