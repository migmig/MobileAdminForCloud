import Foundation
import Combine

@MainActor
class GoodsViewModel: ObservableObject {
    private let goodsService = GoodsService(client: NetworkClient())

    func fetchGoods(_ startFrom: Date?, _ endTo: Date?) async -> [Goodsinfo] {
        await goodsService.fetchGoods(startFrom, endTo) ?? []
    }
}
