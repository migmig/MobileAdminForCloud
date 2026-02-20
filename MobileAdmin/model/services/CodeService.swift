import Foundation
import Logging

struct CodeService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.CodeService")

    func fetchGroupCodeLists() async -> [CmmnGroupCodeItem] {
        do {
            let url = "\(client.baseUrl)/admin/getCmmnGroupCodeList"
            let result: [CmmnGroupCodeItem]? = try await client.makeRequestNoRequestData(url: url)
            return result ?? []
        } catch {
            logger.error("fetchGroupCodeLists 실패: \(error)")
        }
        return []
    }

    func fetchCodeListByGroupCode(_ groupCode: String) async -> [CmmnCodeItem] {
        do {
            let url = "\(client.baseUrl)/admin/getCmmnCodeByCmmnGroupCode/\(groupCode)"
            let result: [CmmnCodeItem]? = try await client.makeRequestNoRequestData(url: url)
            return result ?? []
        } catch {
            logger.error("fetchCodeListByGroupCode 실패: \(error)")
        }
        return []
    }
}
