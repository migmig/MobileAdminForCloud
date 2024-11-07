//
//  FilteredGoodsItem.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/7/24.
//

import SwiftUI

struct  FilteredGoodsItem:View  {
    @Binding var arrGoods:[String]
    @Binding var selectedGoodsCd:[String]
    @Binding var filteredGoodsItems:[Goodsinfo]
    @Binding var goodsItems:[Goodsinfo]
    
    var body: some View {
        HStack{
            Text("Goods:")
            Spacer()
            ScrollView(.horizontal){
                HStack{
                    ForEach(arrGoods, id:\.self){goodsCd in
                        Button(action:{
                            if !selectedGoodsCd.contains(goodsCd){
                                selectedGoodsCd.append(goodsCd)
                                updateFilteredGoodsItems()
                            }else{
                                selectedGoodsCd.removeAll{$0 == goodsCd}
                                updateFilteredGoodsItems()
                            }
                        }){
                            Text(goodsCd)
                                .foregroundColor(selectedGoodsCd.contains(goodsCd) ? Color.blue : Color.gray)
                        }
//                        .foregroundColor(selectedGoodsCd.contains(goodsCd) ? Color.blue : Color.gray) 
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
        }
    }
    
    private func updateFilteredGoodsItems() {
        if selectedGoodsCd.isEmpty {
            filteredGoodsItems = goodsItems
        } else {
            filteredGoodsItems = goodsItems.filter { item in
                item.goods.contains { goods in
                    selectedGoodsCd.contains(goods.goodsCd)
                }
            }
        }
    }
}
