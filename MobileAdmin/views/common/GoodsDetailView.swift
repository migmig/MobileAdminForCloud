
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
                                .foregroundColor(item.maxLmt > 0 ? .blue : .secondary)
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
                    InfoRow(title: "보증번호", value: goodsinfo.gno ?? "")
                    Divider()
                    InfoRow(title: "접수구분", value: goodsinfo.kindGb ?? "")
                    Divider()
                    InfoRow(title: "등록일자", value: goodsinfo.registerDt ?? "")
                    Divider()
                    // macOS용 Table과 iOS용 List로 구분
                    
                    HStack{
                        Text("상품정보")
                            //.font(.headline)
                        Spacer()
                    } 
                    
                     
                    goodsDetailOfDetail()
                    
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

#Preview(
    "Content",
    traits: .fixedLayout(width: 500, height: 500)
)
{
    GoodsDetailView(
        goodsinfo: Goodsinfo("UT000000",
                             "20111104",
                             [Good("N002", "청년어찌고저찌고"),
                              Good("GD01","부채상환연장 특례보증(영업점심사)")])
    )
}
