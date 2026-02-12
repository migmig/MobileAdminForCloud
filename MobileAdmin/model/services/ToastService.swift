import Foundation
import Logging

struct ToastService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.ToastService")

    func fetchToasts() async -> Toast {
        do {
            let url = "\(client.baseUrl)/admin/toastNotice"
            let toast: Toast = try await client.makeRequestNoRequestData(url: url)
            return toast
        } catch {
            logger.error("fetchToasts 실패: \(error)")
        }
        return Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")
    }

    func setNoticeVisible(toastData: Toast) async {
        do {
            let urlPath = "/admin/toastSetVisible/\(toastData.useYn)"
            try await client.makeRequestNoReturn(url: "\(client.baseUrl)\(urlPath)", requestData: toastData)
        } catch {
            logger.error("setNoticeVisible 실패: \(error)")
        }
    }

    func setToastData(toastData: Toast) async {
        do {
            let urlPath = "/admin/toastSetNotice"
            try await client.makeRequestNoReturn(url: "\(client.baseUrl)\(urlPath)", requestData: toastData)
        } catch {
            logger.error("setToastData 실패: \(error)")
        }
    }
}
