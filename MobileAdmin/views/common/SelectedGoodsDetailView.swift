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
        ScrollView{
            VStack{
                InfoRow(title: "상품코드", value: goodsItem.goodsCd  )
                Divider()
                InfoRow(title: "상품명", value: goodsItem.goodsNm  )
                Divider()
                InfoRow(title: "상한액",
                        value: String(goodsItem.maxLmt.formatted(.number))
                   )
                Divider()
                InfoRow2(title: "알림여부"){
                    Toggle("", isOn: .constant(goodsItem.userAlertYn == "Y"))
                        .labelsHidden()
                }
                Divider()
                InfoRow2(title: "거절여부"){
                    Toggle("", isOn: .constant(goodsItem.msgDispYn == "Y"))
                        .labelsHidden()
                }
                Divider()
                InfoRow(title: "보증료율", value: String(goodsItem.feeRate ?? 0))
                Divider()
                InfoRow(title: "금리상한", value: String(goodsItem.inrstMax ?? 0))
                Divider()
                InfoRow(title: "금리하한", value: String(goodsItem.inrstMin ?? 0))
                Divider()
                InfoRow2(title: "자동여부"){
                    Toggle("", isOn: .constant(goodsItem.autoRptYn == "Y"))
                        .labelsHidden()
                }
                Divider()
                InfoRow(title: "거절메세지", value: goodsItem.dispMsg ?? "")
                Divider()
                InfoRow2(title: "팝업표시여부"){
                    Toggle("", isOn: .constant(goodsItem.popDispYn == "Y"))
                        .labelsHidden()
                }
                Divider()
                InfoRow2(title: "별도안내내용"){
                    HStack{
                        if let treatmentList = goodsItem.treatmentList{
                            ForEach(treatmentList, id:\.self){
                                 
                                    Button("\($0.treatmentNm ?? "")"){
                                        
                                    }
                                    .font(.caption)
                                    .buttonStyle(BorderedButtonStyle())
                                
                            }
//                            ForEach(treatmentList ,id:\.self){ item in
//                                Button("\(item.treatmentNm ?? "")")
//                            }
//                            List(treatmentList,id:\.self){ item in
//                                Text("\(item.treatmentNm ?? "")")
//                            }
                           // .frame(maxWidth:300 )
                        }else{
                            Text("No Data")
                        }
                    }
                   // .frame(minHeight: 60 )
                }//.frame(maxHeight:.infinity)
                Divider()
                InfoRow2(title: "메세지출력여부"){
                    HStack{
                        if let goodsContList = goodsItem.goodsContList{
                            ForEach(goodsContList,id:\.self){ item in
                                Button("\(item.userMsgTitle ?? "")"){
                                    selectedMessage = item.msgUseContent ?? ""
                                    isDialogPresented = selectedMessage == "" ? false : true
                                }
                                .font(.caption) 
                                .buttonStyle(BorderedButtonStyle())
                                .alert(item.userMsgTitle ?? " "
                                    , isPresented: $isDialogPresented
                                 ){
                                    Button("확인"){
                                        isDialogPresented = false
                                    }
                                }message:{
                                    Text(selectedMessage)
                                }
                            }
                        }else{
                            Text("")
                        }
                    }
                }
                Divider()
                InfoRow2(title: "은행정보"){
                    HStack{
                        if let bankIemList = goodsItem.bankIemList{
                            ForEach(bankIemList,id:\.self){ item in
                                Button("\(item.iemCodeNm ?? "")"){
                                    
                                }
                                    .font(.caption)
                                    .buttonStyle(BorderedButtonStyle())
                            }
                        }else{
                            Text("")
                        }
                    }
                   // .frame(minHeight: 60,maxHeight:.infinity)
                }
            }
            .padding()
        }
        .navigationTitle("상품정보")
        #if os(macOS)
        .navigationSubtitle("상품정보")
        #endif
    }
}
#Preview(
   traits: .fixedLayout(width: 500, height: 1200)
){
    let good = Good("N002","직접짐사",10000000)
   // good.treatmentList = [TreatmentList("1","1","1","Y","treatmentNm")]
    SelectedGoodsDetailView(goodsItem: good)
}
