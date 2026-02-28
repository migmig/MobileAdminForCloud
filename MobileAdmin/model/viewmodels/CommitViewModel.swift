import Foundation

@MainActor
class CommitViewModel: ObservableObject {
    @Published var sourceCommitInfoRepository: [SourceCommitInfoRepository] = []

    private let commitService = CommitService(client: NetworkClient())

    func fetchSourceCommitList() async {
        let result = await commitService.fetchSourceCommitList()
        sourceCommitInfoRepository = result.result.repository.sorted { $0.id < $1.id }
    }

    func fetchSourceCommitBranchList(_ repositoryName: String) async -> SourceCommitBranchInfo {
        await commitService.fetchSourceCommitBranchList(repositoryName)
    }
}
