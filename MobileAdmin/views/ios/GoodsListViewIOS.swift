import SwiftUI

struct GoodsListViewIOS: View {
    @EnvironmentObject var goodsViewModel: GoodsViewModel
    @State var goodsItems: [Goodsinfo] = []
    @State private var filteredGoodsItems: [Goodsinfo] = []
    @State private var isLoading: Bool = false
    @State private var dateFrom: Date = Date()
    @State private var dateTo: Date = Date()
    @State private var arrGoods: [String] = []
    @State private var selectedGoodsCd: [String] = []
    @State private var searchText: String = ""

    var filteredGoods: [Goodsinfo] {
        guard !searchText.isEmpty else { return filteredGoodsItems }
        return filteredGoodsItems.filter {
            $0.userId?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        List {
            Section {
                SearchArea(dateFrom: $dateFrom,
                           dateTo: $dateTo,
                           isLoading: $isLoading,
                           clearAction: {
                    selectedGoodsCd.removeAll()
                    searchText = ""
                }) {
                    await loadGoods()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                FilteredGoodsItem(
                    arrGoods: $arrGoods,
                    selectedGoodsCd: $selectedGoodsCd,
                    filteredGoodsItems: $filteredGoodsItems,
                    goodsItems: $goodsItems
                )

                if !selectedGoodsCd.isEmpty {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(AppColor.link)
                            .font(AppFont.caption)
                        Text("\(filteredGoodsItems.count)건 필터됨")
                            .font(AppFont.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            selectedGoodsCd = []
                            filteredGoodsItems = goodsItems
                        }) {
                            Label("초기화", systemImage: "xmark.circle")
                                .font(AppFont.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            Section {
                if filteredGoods.isEmpty && !isLoading {
                    EmptyStateView(
                        systemImage: "cart",
                        title: "상품 이력이 없습니다",
                        description: "조회 조건을 변경해 보세요"
                    )
                    .listRowBackground(Color.clear)
                }
                ForEach(filteredGoods) { entry in
                    NavigationLink(destination: GoodsDetailView(goodsinfo: entry)) {
                        GoodsItemListItem(
                            goodsItem: entry,
                            selectedGoodsCd: selectedGoodsCd
                        )
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .automatic)
        .navigationTitle("상품 조회")
        .loadingTask(isLoading: $isLoading) {
            await loadGoods()
        }
        .refreshable {
            await loadGoods()
        }
    }

    private func loadGoods() async {
        isLoading = true
        goodsItems = await goodsViewModel.fetchGoods(dateFrom, dateTo)
        let codes = Set(goodsItems.flatMap { $0.goods.map { $0.goodsCd } })
        arrGoods = Array(codes)
        filteredGoodsItems = goodsItems
        isLoading = false
    }
}

#Preview {
    GoodsListViewIOS()
        .environmentObject(GoodsViewModel())
}
