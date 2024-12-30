
import SwiftUI

struct GoodsDetailView: View {
    var goodsinfo:Goodsinfo
    
    fileprivate func goodsDetailOfDetail() -> some View{
        return Grid(alignment:.trailing)
        {
            ForEach(goodsinfo.goods, id: \.self) { item in
                NavigationLink(destination: SelectedGoodsDetailView(goodsItem: item)) {
                    GridRow{
                        VStack(alignment: .trailing) {
                            HStack{
                                Image(systemName:"cart.circle")
                                Text("\(item.goodsCd)")
                                    .font(.headline)
                                Spacer()
                            Text("\(item.goodsNm)")
                                    .foregroundColor(item.maxLmt > 0 && item.msgDispYn != "Y" ? .blue : .secondary)
                                .font(.subheadline)
                            }
                        }
                        //.padding()
                        // .padding(.horizontal)
                    }
                    .padding(3)
                }
            }
        }
    }
    
    func getGnoWithDash(gno : String?) -> String{
        
        if gno == nil || gno!.isEmpty{
            return ""
        }else{
            return gno!.prefix(3) + "-" + gno!.dropFirst(3).prefix(4) + "-" + gno!.suffix(5)
        }
    }
    
    var body: some View {
        ScrollView{
            LazyVStack{
                Section(header: Text("상세 정보").font(.headline)) {
                    
                    InfoRow(title: "사용자아이디", value: goodsinfo.userId ?? "")
                    Divider()
                    InfoRow(
                        title: "접수일자",
                        value: Util.convertToFormattedDate(goodsinfo.rdt)
                    )
                    Divider()
                    InfoRow(
                        title: "보증번호",
                        value: getGnoWithDash(gno: goodsinfo.gno)
                    )
                    Divider()
                    InfoRow(title: "접수구분", value: goodsinfo.kindGb ?? "")
                    Divider()
                    InfoRow(
                        title: "등록일자",
                        value: Util.convertToFormattedDate(goodsinfo.registerDt)
                    )
                    Divider()
                    
                    HStack{
                        Text("상품정보")
                        Spacer()
                    }
                    
                     
                    goodsDetailOfDetail()
                    
                    Divider()
                }
            }
            .padding()
        }
//        .navigationDestination(for:Good.self){item2 in
//            SelectedGoodsDetailView(goodsItem:item2)
//        }
        .onAppear{
        }
        
#if os(iOS)
        .navigationTitle(Util.formatDateTime(goodsinfo.registerDt))
#elseif os(macOS)
        .navigationSubtitle(Util.formatDateTime(goodsinfo.registerDt))
#endif
    }
}

#Preview(
    "Content",
    traits: .fixedLayout(width: 500, height: 500)
)
{
    GoodsDetailView(
        goodsinfo: Goodsinfo(id: 1,
                             userid:"UT000000",
                             rdt:"20111104",
                             gno:"110202401958",
                             kindGb:"G",
                             registerDt:"20211104",
                             goods:[Good("N002", "청년어찌고저찌고"),
                                    Good("GD01","부채상환연장 특례보증(영업점심사)"),
                                    Good("GD02","부채상연장 특례보증(영업점심사)"),
                                    Good("GD03","부상환연장 특례보증(영업점심사)")])
    )
}
