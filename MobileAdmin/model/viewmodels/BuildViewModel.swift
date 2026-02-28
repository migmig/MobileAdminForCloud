import Foundation
import Combine

@MainActor
class BuildViewModel: ObservableObject {
    @Published var buildProjects: [SourceBuildProject] = []

    private let buildService = BuildService(client: NetworkClient())

    func fetchSourceBuildList() async {
        let result = await buildService.fetchSourceBuildList()
        buildProjects = result.result.project.sorted { $0.id < $1.id }
    }

    func fetchSourceBuildInfo(_ buildId: Int) async -> SourceBuildInfo? {
        await buildService.fetchSourceBuildInfo(buildId)
    }

    func execSourceBuild(_ buildId: Int) async -> BuildExecResult? {
        await buildService.execSourceBuild(buildId)
    }

    func fetchSourceBuildHistory(_ buildId: Int) async -> SourceBuildHistoryInfo? {
        await buildService.fetchSourceBuildHistory(buildId)
    }
}
