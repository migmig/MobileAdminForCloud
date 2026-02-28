import Foundation
import Combine

@MainActor
class EducationViewModel: ObservableObject {
    @Published var edcCrseCllist: [EdcCrseCl] = []

    private let educationService = EducationService(client: NetworkClient())

    func fetchClsLists() async {
        let result = await educationService.fetchClsLists()
        edcCrseCllist = result.edcCrseClAllList ?? []
    }

    func fetchClsInfo(edcCrseId: Int) async -> EdcCrseResponse {
        await educationService.fetchClsInfo(edcCrseId: edcCrseId)
    }
}
