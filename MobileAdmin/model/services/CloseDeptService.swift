import Foundation
import Logging

struct CloseDeptService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.CloseDeptService")

    func fetchCloseDeptList() async -> CloseInfo {
        do {
            let url = "\(client.baseUrl)/admin/getStartEndOfDept"
            let result: CloseInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? CloseInfo()
        } catch {
            logger.error("fetchCloseDeptList 실패: \(error)")
        }
        return CloseInfo()
    }
}
