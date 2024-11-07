//
//  GoodsSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/5/24.
//

import SwiftUI

struct GoodsSidebar: View {
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @Binding var goodsItems:[Goodsinfo]
    @Binding var selectedGoods:Goodsinfo?
    @State   var isLoading:Bool = false
    @State var dateFrom:Date = Date()
    @State var dateTo:Date = Date()
    @State private var arrGoods:[String] = []
    @State private var selectedGoodsCd:[String] = []
    @State private var filteredGoodsItems:[Goodsinfo] = []
    
    
    var body: some View {
        SearchArea(dateFrom: $dateFrom,
                   dateTo: $dateTo,
                   isLoading: $isLoading,
                   clearAction:{
                        selectedGoodsCd.removeAll()
                    }
        ){
            goodsItems = await viewModel
                .fetchGoods(dateFrom, dateTo) ?? []
            let arr  = Set(goodsItems.flatMap{item in
                item.goods.map{$0.goodsCd}
            })
            arrGoods = Array(arr)
            filteredGoodsItems = goodsItems
        }.padding()
        
        if isLoading {
            ProgressView(" ")
                .progressViewStyle(CircularProgressViewStyle())
        }
        
        FilteredGoodsItem(
            arrGoods: $arrGoods,
            selectedGoodsCd: $selectedGoodsCd,
            filteredGoodsItems: $filteredGoodsItems,
            goodsItems: $goodsItems
        )
        .padding()
        
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
        List(filteredGoodsItems,selection:$selectedGoods){ item in
            NavigationLink(value:item){
                GoodsItemListItem(
                    goodsItem: item
                    , selectedGoodsCd: selectedGoodsCd
                )
            }
        }.onAppear()
        {
            Task{
                isLoading = true;
                // await goodsItems = viewModel.fetchGoods(dateFrom,dateTo) ?? []
                isLoading = false;
            }
        }
    }
}

#Preview {
    GoodsSidebar(
        goodsItems: .constant([Goodsinfo("UT000000", "20111104")]),
        selectedGoods: .constant(Goodsinfo("UT000000", "20111104"))
    )
}
