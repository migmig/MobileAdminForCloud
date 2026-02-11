
import SwiftUI

struct GoodsDetailView: View {
    var goodsinfo:Goodsinfo
    
    func getGnoWithDash(gno : String?) -> String{
        
        if gno == nil || gno!.isEmpty{
            return ""
        }else{
            return gno!.prefix(3) + "-" + gno!.dropFirst(3).prefix(4) + "-" + gno!.suffix(5)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // MARK: - 접수 정보
                CardView(title: "접수 정보", systemImage: "doc.text") {
                    InfoRow(title: "사용자아이디", value: goodsinfo.userId ?? "")
                    InfoRow(title: "접수일자", value: Util.convertToFormattedDate(goodsinfo.rdt))
                    InfoRow(title: "보증번호", value: getGnoWithDash(gno: goodsinfo.gno))
                    InfoRow(title: "접수구분", value: goodsinfo.kindGb ?? "")
                    InfoRow(title: "등록일자", value: Util.formatDateTime(goodsinfo.registerDt))
                }

                // MARK: - 상품 목록
                CardView(title: "상품 정보 (\(goodsinfo.goods.count)건)", systemImage: "cart") {
                    ForEach(goodsinfo.goods, id: \.self) { item in
                        NavigationLink(destination: SelectedGoodsDetailView(goodsItem: item)) {
                            HStack(spacing: AppSpacing.md) {
                                Text(item.goodsCd)
                                    .font(AppFont.mono)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(
                                        (item.maxLmt > 0 && item.msgDispYn != "Y"
                                            ? AppColor.link : Color.secondary).gradient
                                    )
                                    .cornerRadius(AppRadius.xs)

                                Text(item.goodsNm)
                                    .font(AppFont.listSubtitle)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(AppFont.captionSmall)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .groupedBackground()
#if os(iOS)
        .navigationTitle("상세정보")
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
