import Foundation

@MainActor
class ErrorViewModel: ObservableObject {
    @Published var errorItems: [ErrorCloudItem] = []
    @Published var selectedErrors: Set<Int> = []

    private let errorService = ErrorService(client: NetworkClient())
    private let userLogService = UserLogService(client: NetworkClient())

    func fetchErrors(startFrom: Date, endTo: Date) async {
        errorItems = await errorService.fetchErrors(startFrom: startFrom, endTo: endTo) ?? []
    }

    func deleteError(id: Int) async {
        await errorService.deleteError(id: id)
    }

    func downloadUserLog(_ sno: String) async throws -> URL {
        try await userLogService.downloadUserLog(sno)
    }

    func toggleSelection(errorId: Int?) {
        guard let id = errorId else { return }
        if selectedErrors.contains(id) { selectedErrors.remove(id) }
        else { selectedErrors.insert(id) }
    }

    func selectAll() { selectedErrors = Set(errorItems.compactMap { $0.id }) }
    func deselectAll() { selectedErrors.removeAll() }

    var selectedCount: Int { selectedErrors.count }
    var canDeleteMultiple: Bool { !selectedErrors.isEmpty }
}
