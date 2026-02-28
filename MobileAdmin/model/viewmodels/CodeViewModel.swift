import Foundation
import Combine

@MainActor
class CodeViewModel: ObservableObject {
    private let codeService = CodeService(client: NetworkClient())

    func fetchGroupCodeLists() async -> [CmmnGroupCodeItem] {
        await codeService.fetchGroupCodeLists()
    }

    func fetchCodeListByGroupCode(_ groupCode: String) async -> [CmmnCodeItem] {
        await codeService.fetchCodeListByGroupCode(groupCode)
    }
}
