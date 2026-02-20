import Foundation
import Logging

struct EducationService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.EducationService")

    func fetchClsLists() async -> EdcCrseClListResponse {
        do {
            let url = "\(client.baseUrl)/gcamp/category/all-edu-list"
            let result: EdcCrseClListResponse? = try await client.makeRequestNoRequestData(url: url)
            return result ?? EdcCrseClListResponse()
        } catch {
            logger.error("fetchClsLists 실패: \(error)")
        }
        return EdcCrseClListResponse()
    }

    func fetchClsInfo(edcCrseId: Int) async -> EdcCrseResponse {
        do {
            let url = "\(client.baseUrl)/gcamp/category/education-crse-info"
            let resp: EdcCrseResponse? = try await client.makeRequest(
                url: url,
                requestData: EdcCrseClRequest(edcCrseId: edcCrseId)
            )
            return resp ?? EdcCrseResponse()
        } catch {
            logger.error("fetchClsInfo 실패: \(error)")
        }
        return EdcCrseResponse()
    }
}
