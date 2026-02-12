//
//  SelectedGoodsDetailView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/4/24.
//
import SwiftUI

struct SelectedGoodsDetailView:View{
    var goodsItem:Good
    @State private var isDialogPresented: Bool = false
    @State private var selectedMessage: String = ""
    
    
    var body: some View{
        List{
            Section("상품정보"){
                InfoRow(title: "상품코드", value: goodsItem.goodsCd  )
                InfoRow(title: "상품명"  , value: goodsItem.goodsNm  )
                InfoRow(title: "상한액"  , value: String(goodsItem.maxLmt.formatted(.number)) )
                InfoRowCustom(title: "알림여부"){
                    Toggle("", isOn: .constant(goodsItem.userAlertYn == "Y"))
                        .labelsHidden()
                }
                InfoRowCustom(title: "거절여부"){
                    Toggle("", isOn: .constant(goodsItem.msgDispYn == "Y"))
                        .labelsHidden()
                }
                InfoRow(title: "보증료율", value: String(goodsItem.feeRate ?? 0))
                InfoRow(title: "금리상한", value: String(goodsItem.inrstMax ?? 0))
                InfoRow(title: "금리하한", value: String(goodsItem.inrstMin ?? 0))
                InfoRowCustom(title: "자동여부"){
                    Toggle("", isOn: .constant(goodsItem.autoRptYn == "Y"))
                        .labelsHidden()
                }
                InfoRow(title: "거절메세지", value: goodsItem.dispMsg ?? "")
                InfoRowCustom(title: "팝업표시여부"){
                    Toggle("", isOn: .constant(goodsItem.popDispYn == "Y"))
                        .labelsHidden()
                }
            }
            Section("별도안내내용")
            {
                if let treatmentList = goodsItem.treatmentList{
                    ForEach(treatmentList, id:\.self){
                        Text($0.treatmentNm ?? "")
                    }
                }else{
                    Text("No Data")
                }
            }
            if let bankIemList = goodsItem.bankIemList{
                if !bankIemList.isEmpty{
                    Section("은행정보"){
                        ForEach(bankIemList,id:\.self){ item in
                            Text("\(item.iemCodeNm ?? "")")
                        }
                    }
                }
            }
            if let goodsContList = goodsItem.goodsContList{
                if !goodsContList.isEmpty{
                    Section("메세지출력여부"){
                        ForEach(goodsContList,id:\.self){ item in
                            if item.msgUseContent != nil{
                                NavigationLink("\(item.userMsgTitle ?? "")", destination: List{Text(item.msgUseContent ?? "").padding()})
                            }else{
                                Text("\(item.userMsgTitle ?? "")")
                            }
                        }
                    } //Section
                }
            } //if
        } //List
#if os(iOS)
        .listStyle(GroupedListStyle())
#endif
        .navigationTitle("상품정보")
        #if os(macOS)
        .navigationSubtitle("상품정보")
        #endif
    }
}
//#Preview(
//   traits: .fixedLayout(width: 500, height: 1200)
//){
//    var good = Good("N002","직접짐사",10000000,[
//        TreatmentList("1","1","1","Y","treatmentNm1"),
//        TreatmentList("1","1","1","Y","treatmentNm2"),
//        TreatmentList("1","1","1","Y","treatmentNm3"),
//        TreatmentList("1","1","1","Y","treatmentNm4"),
//        TreatmentList("1","1","1","Y","treatmentNm5")
//    ])
//    SelectedGoodsDetailView(goodsItem: good)
//}
