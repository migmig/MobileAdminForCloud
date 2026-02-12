import Foundation
import Logging

struct GoodsService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.GoodsService")

    func fetchGoods(_ startFrom: Date?, _ endTo: Date?) async -> [Goodsinfo]? {
        do {
            let p_startFrom = Util.getCurrentDateString("yyyyMMdd", startFrom)
            let p_endTo     = Util.getCurrentDateString("yyyyMMdd", endTo)
            let urlPath     = "/admin/getGoodsHistList/\(p_startFrom)/\(p_endTo)"
            let goodsinfos: [Goodsinfo] = try await client.makeRequestNoRequestData(url: "\(client.baseUrl)\(urlPath)")
            return goodsinfos
        } catch {
            logger.error("fetchGoods 실패: \(error)")
        }
        return nil
    }
}
