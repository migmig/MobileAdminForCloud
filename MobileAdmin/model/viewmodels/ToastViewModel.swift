import Foundation
import Combine

@MainActor
class ToastViewModel: ObservableObject {
    private let toastService = ToastService(client: NetworkClient())

    func fetchToasts() async -> Toast {
        await toastService.fetchToasts()
    }

    func setNoticeVisible(toastData: Toast) async {
        await toastService.setNoticeVisible(toastData: toastData)
    }

    func setToastData(toastData: Toast) async {
        await toastService.setToastData(toastData: toastData)
    }
}
