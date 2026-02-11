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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // 사용자 + 날짜
            HStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "person.circle")
                        .font(AppFont.captionSmall)
                        .foregroundColor(AppColor.userIcon)
                    Text(goodsItem.userId ?? "")
                        .font(AppFont.listTitle)
                }

                Spacer()

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "calendar")
                        .font(AppFont.captionSmall)
                    Text(Util.convertToFormattedDate(goodsItem.rdt))
                        .font(AppFont.caption)
                        .monospacedDigit()
                }
                .foregroundColor(.secondary)
            }

            // 상품코드 태그
            if !goodsItem.goods.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "tag.fill")
                        .font(AppFont.captionSmall)
                        .foregroundColor(.secondary)
                    ForEach(Array(goodsItem.goods.enumerated()), id:\.element) { index, good in
                        Text(good.goodsCd)
                            .font(AppFont.captionSmall)
                            .fontWeight(.medium)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(
                                selectedGoodsCd.contains(good.goodsCd)
                                    ? AppColor.selected.opacity(0.12)
                                    : Color.secondary.opacity(0.08)
                            )
                            .foregroundColor(
                                selectedGoodsCd.contains(good.goodsCd)
                                    ? AppColor.selected
                                    : AppColor.deselected
                            )
                            .cornerRadius(AppRadius.xs)
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.xxs)
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
