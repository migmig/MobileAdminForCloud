import Foundation
import Logging

struct ErrorService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.ErrorService")

    func fetchErrors(startFrom: Date, endTo: Date) async -> [ErrorCloudItem]? {
        do {
            let urlPath = "/admin/findByRegisterDtBetween/\(Util.getFormattedDateString(startFrom))/\(Util.getFormattedDateString(endTo))"
            let errorItems: [ErrorCloudItem] = try await client.makeRequestNoRequestData(url: "\(client.baseUrl)\(urlPath)")
            return errorItems
        } catch {
            logger.error("fetchErrors 실패: \(error)")
        }
        return nil
    }

    func deleteError(id: Int) async {
        do {
            let urlPath = "/admin/cloud/error/delete/\(id)"
            let _: [ErrorCloudItem] = try await client.makeRequestNoRequestData(url: "\(client.baseUrl)\(urlPath)")
        } catch {
            logger.error("deleteError 실패: \(error)")
        }
    }
}
