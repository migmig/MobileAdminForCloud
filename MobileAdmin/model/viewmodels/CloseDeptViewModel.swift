import Foundation
import Combine

@MainActor
class CloseDeptViewModel: ObservableObject {
    private let closeDeptService = CloseDeptService(client: NetworkClient())

    func fetchCloseDeptList() async -> CloseInfo {
        await closeDeptService.fetchCloseDeptList()
    }
}
