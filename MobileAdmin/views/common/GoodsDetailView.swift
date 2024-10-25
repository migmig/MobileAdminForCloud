 
import SwiftUI

struct GoodsDetailView: View {
    var goodsinfo:Goodsinfo
    @State private var showingSheet:Bool = false
    @State private var selectedGoods:Set<Good.ID>?
    var body: some View {
        ScrollView{
            VStack{
                Section(header: Text("상세 정보").font(.headline)) {
                    Table(of:Good.self){
                        TableColumn("goodsCd"){
                            Text($0.goodsCd  )
                        }
                        TableColumn("goodsNm" ) {
                            Text($0.goodsNm )
                        }
                    } rows:{
                        ForEach(goodsinfo.goods,id:\.self){item in
                            TableRow(item)
                        }
                    }
                    InfoRow(title: "userId", value: goodsinfo.userId ?? "")
                    InfoRow(title: "rdt", value: goodsinfo.rdt ?? "")
                    InfoRow(title: "gno", value: goodsinfo.gno ?? "")
                    InfoRow(title: "kindGb", value: goodsinfo.kindGb ?? "")
                    InfoRow(title: "registerDt", value: goodsinfo.registerDt ?? "")
                    // macOS용 Table과 iOS용 List로 구분
                  #if os(macOS)
                  Text("Goods Table (macOS)")
                      .font(.headline)
                      .padding(.vertical, 5)
                  
                  Table(goodsinfo.goods  ) {
                      TableColumn("Goods Code") { item in
                          Text(item.goodsCd  )
                      }
                      TableColumn("Goods Name") { item in
                          Text(item.goodsNm  )
                      }
                  }
                  .frame(height: 200)  // 테이블 높이 설정
                  #else
                  // iOS 대체 UI (List)
                  Text("Goods List (iOS)")
                      .font(.headline)
                      .padding(.vertical, 5)
                  
                  List(goodsinfo.goods ?? [], id: \.goodsCd) { item in
                      VStack(alignment: .leading) {
                          Text("goodsCd: \(item.goodsCd ?? "N/A")")
                          Text("goodsNm: \(item.goodsNm ?? "N/A")")
                              .foregroundColor(.secondary)
                      }
                      .padding(.vertical, 5)
                  }
                  .frame(height: 200)
                  #endif
//                        VStack{
//                            ForEach(goodsinfo.goods,id:\.self){item in
//                                HStack{
//                                    Text("goodsCd: \(item.goodsCd ?? ""), goodsNm: \(item.goodsNm ?? "")")
//                                    Spacer()
//                                    NavigationLink(value:item){
//                                        Text("상품상세")
//                                            .foregroundColor(.gray)
//                                    }
//                                    .navigationDestination(for:Good.self){item2 in
//                                        SelectedGoodsDetailView(goodsItem:item2)
//                                    }
//                                }
//                            }
//                        }
                    }
                    .padding(.vertical, 10)
                }
                .padding()
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
            List{
                    InfoRow(title: "상품코드", value: goodsItem.goodsCd ?? "")
                    InfoRow(title: "maxLmt", value: String(goodsItem.maxLmt ?? 0))
                    InfoRow(title: "finProdType", value: goodsItem.finProdType ?? "")
                    InfoRow(title: "userAlertYn", value: goodsItem.userAlertYn ?? "")
                    InfoRow(title: "msgDispYn", value: goodsItem.msgDispYn ?? "")
                    InfoRow(title: "feeRate", value: String(goodsItem.feeRate ?? 0))
                    InfoRow(title: "inrstMax", value: String(goodsItem.inrstMax ?? 0))
                    InfoRow(title: "autoRptYn", value: goodsItem.autoRptYn ?? "")
                    InfoRow(title: "dispMsg", value: goodsItem.dispMsg ?? "")
                    InfoRow(title: "popDispYn", value: goodsItem.popDispYn ?? "")
                    InfoRow(title: "inrstMin", value: String(goodsItem.inrstMin ?? 0))
//                    HStack{
//                        Text("treatmentList")
//                        Spacer()
//                        NavigationLink(value:item.treatmentList){
//                            Text("상품상세")
//                                .foregroundColor(.gray)
//                        }
//                        .navigationDestination(for:[TreatmentList].self){treatment in
//                            ScrollView{
//                                List{
//                                    ForEach(treatment,id:\.self){treatmentitem in
//                                        InfoRow(title: "treatmentCd", value: treatmentitem.treatmentCd ?? "")
//                                        InfoRow(title: "useYn", value: treatmentitem.useYn ?? "")
//                                        InfoRow(title: "treatmentNm", value: treatmentitem.treatmentNm ?? "")
//                                    }
//                                }
//                            }
//                        }
//                    }
            }
        }
    }
}
