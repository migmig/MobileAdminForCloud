//
//  GoodsItemListItem.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/23/24.
//

import SwiftUI

struct GoodsItemListItem: View {
    let goodsItem:Goodsinfo
    
    init(_ goodsItem:Goodsinfo){
        self.goodsItem = goodsItem
    }
    
    var body: some View {
        Image(systemName: "info.bubble")
        Text(goodsItem.userId ?? "")
        Spacer().frame(width:3)
        Divider()
        Text(goodsItem.rdt ?? "")
        
    }
}
  
