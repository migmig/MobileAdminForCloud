//
//  GoodsItemListItem.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/23/24.
//

import SwiftUI

struct GoodsItemListItem: View {
    
    let goodsItem:Goodsinfo
   var selectedGoodsCd:[String]
     
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Image(systemName: "info.bubble")
                    .font(.caption)
                VStack(alignment: .leading){
                    Text(goodsItem.userId  ?? ""  )
//                        .font(.caption)
//                        .frame(maxWidth:130)
                }
                Spacer()
                Image(systemName:"calendar")
                    .font(.caption)
                Text(Util.convertToFormattedDate(goodsItem.rdt))
//                    .font(.caption)
            }
               // VStack(alignment: .trailing) {
                    HStack{
                    VStack(alignment: .trailing) {
                        if(!goodsItem.goods.isEmpty){
                            HStack(spacing:1){
                                Image(systemName:"folder.fill")
                                    .font(.caption)
                                ForEach(Array(
                                    goodsItem.goods.enumerated()),
                                        id:\.element
                                ){index, good in
                                    
                                    Text("\(index == 0 ? "" : ",")\(good.goodsCd)")
                                        .font(.caption)
                                        .foregroundColor(selectedGoodsCd.contains(good.goodsCd) ? AppColor.selected : AppColor.deselected)
                                    
                                }
                                //                            Text(goodsItem.goods.map({$0.goodsCd}).joined(separator:","))
                                //                                .font(.caption)
                            }
                        }
                    }
                //}
            }
        }
        
        
    }
}

#Preview{
    TabView {
        VStack{
            List{
                GoodsItemListItem(
                    goodsItem: Goodsinfo(
                        "UT00012300016",
                        "20111104",
                        [Good("N002"),Good("N001"),Good("N001"),Good("N001")]
                    )
                    ,
                    selectedGoodsCd: ([])
                )
                GoodsItemListItem(
                    goodsItem: Goodsinfo(
                        "UT00002001016",
                        "20111104",
                        [Good("N002"),Good("N001")]
                    )
                    ,
                    selectedGoodsCd: ([])
                )
                GoodsItemListItem(
                    goodsItem: Goodsinfo(
                        "UT00002001016",
                        "20111104",
                        [Good("N002"),Good("N001")]
                    )
                    ,
                    selectedGoodsCd: ([])
                )
                GoodsItemListItem(
                    goodsItem: Goodsinfo(
                        "UT00002001016",
                        "20111104",
                        [Good("N002"),Good("N001")]
                    )
                    ,
                    selectedGoodsCd: ([])
                )
            }
        }.padding()
    }
    .font(.custom("D2Coding", size: 16))
    .tabItem {
        Label("GoodsInfo", systemImage: "cart")
    }
}
