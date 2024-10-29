
import SwiftUI

struct GoodsDetailView: View {
    var goodsinfo:Goodsinfo
    
    var body: some View {
        ScrollView{
            LazyVStack{
                Section(header: Text("상세 정보").font(.headline)) {
                
                    InfoRow(title: "userId", value: goodsinfo.userId ?? "")
                    Divider()
                    InfoRow(title: "rdt", value: goodsinfo.rdt ?? "")
                    Divider()
                    InfoRow(title: "gno", value: goodsinfo.gno ?? "")
                    Divider()
                    InfoRow(title: "kindGb", value: goodsinfo.kindGb ?? "")
                    Divider()
                    InfoRow(title: "registerDt", value: goodsinfo.registerDt ?? "")
                    Divider()
                    // macOS용 Table과 iOS용 List로 구분
  
                    HStack{
                        Text("상품정보")
                            .font(.headline)
                        Spacer()
                    }
                    LazyVGrid(
                        columns:Array(
                            repeating:GridItem(.flexible()),
                            count:2
                        ),
                        spacing:20
                    ){
                        ForEach(goodsinfo.goods, id: \.self) { item in
                            NavigationLink(destination: SelectedGoodsDetailView(goodsItem: item)) {
                                VStack(alignment: .leading) {
                                    Text("상품코드: \(item.goodsCd)")
                                        .font(.headline)
                                    Text("상품명: \(item.goodsNm)")
                                        .foregroundColor(item.maxLmt > 0 ? .blue : .secondary)
                                        .font(.subheadline)
                                }
                                .padding()
//                                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                                .padding(.horizontal)
                            }
                        }
//                        VStack{
//                            List(goodsinfo.goods  , id: \.self) { item in
//                                NavigationLink(value:item){
//                                    VStack(alignment:.trailing){
//                                        Text("상품코드: \(item.goodsCd )")
//                                        Text("상품명: \(item.goodsNm )")
//                                            .foregroundColor(item.maxLmt > 0 ? .blue : .secondary)
//                                            .font(.subheadline)
//                                    }
//                                    
//                                }
//                            }
                        }
                    
                    Divider()
                }
            }
            .padding()
        }
        .navigationDestination(for:Good.self){item2 in
            SelectedGoodsDetailView(goodsItem:item2)
        }
        .onAppear{
        }
        
#if os(iOS)
        .navigationTitle(Util.formatDateTime(goodsinfo.registerDt))
#elseif os(macOS)
        .navigationSubtitle(Util.formatDateTime(goodsinfo.registerDt))
#endif
    }
}

struct SelectedGoodsDetailView:View{
    var goodsItem:Good
    
    var body: some View{
        ScrollView{
            VStack{
                InfoRow(title: "상품코드", value: goodsItem.goodsCd  )
                Divider()
                InfoRow(title: "maxLmt", value: String(goodsItem.maxLmt ))
                Divider()
                InfoRow(title: "finProdType", value: goodsItem.finProdType ?? "")
                Divider()
                InfoRow(title: "userAlertYn", value: goodsItem.userAlertYn ?? "")
                Divider()
                InfoRow(title: "msgDispYn", value: goodsItem.msgDispYn ?? "")
                Divider()
                InfoRow(title: "feeRate", value: String(goodsItem.feeRate ?? 0))
                Divider()
                InfoRow(title: "inrstMax", value: String(goodsItem.inrstMax ?? 0))
                Divider()
                InfoRow(title: "autoRptYn", value: goodsItem.autoRptYn ?? "")
                Divider()
                InfoRow(title: "dispMsg", value: goodsItem.dispMsg ?? "")
                Divider()
                InfoRow(title: "popDispYn", value: goodsItem.popDispYn ?? "")
                Divider()
                InfoRow(title: "inrstMin", value: String(goodsItem.inrstMin ?? 0))
                HStack{
                    Text("별도안내내용")
                    Spacer()
                    VStack{
                        if let treatmentList = goodsItem.treatmentList{
                            List(treatmentList,id:\.self){ item in
                                Text("\(item.treatmentNm ?? "")")
                            }
                        }else{
                            Text("No Data")
                        }
                    }
                }
                HStack{
                    Text("메세지출력여부")
                    Spacer()
                    VStack{
                        if let goodsContList = goodsItem.goodsContList{
                            List(goodsContList,id:\.self){ item in
                                HStack{
                                    Text("userMsgTitle: \(item.userMsgTitle ?? "")")
                                    Text("msgUseContent: \(item.msgUseContent ?? "")")
                                }
                            }
                        }else{
                            Text("")
                        }
                    }
                }
                HStack{
                    Text("은행정보")
                    Spacer()
                    VStack{
                        if let bankIemList = goodsItem.bankIemList{
                            List(bankIemList,id:\.self){ item in
                                HStack{
                                    Text("\(item.iemCodeNm ?? "")")
                                }
                            }
                        }else{
                            Text("")
                        }
                    }
                }
            }
            .padding()
        }
    }
}
