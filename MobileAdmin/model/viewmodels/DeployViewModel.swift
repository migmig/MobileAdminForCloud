import Foundation

@MainActor
class DeployViewModel: ObservableObject {
    @Published var sourceDeployList: [SourceInfoProjectInfo] = []
    @Published var sourceDeployHistoryList: [SourceDeployHistoryInfoHistoryList] = []

    private let deployService = DeployService(client: NetworkClient())

    func fetchSourceDeployList() async {
        let result = await deployService.fetchSourceDeployList()
        sourceDeployList = result.result.projectList.sorted { $0.id < $1.id }
    }

    func fetchSourceDeployHistoryInfo(_ projectId: Int) async -> SourceDeployHistoryInfo {
        await deployService.fetchSourceDeployHistoryInfo(projectId)
    }

    func fetchSourceDeployStageInfo(_ projectId: Int) async -> SourceDeployStageInfo {
        await deployService.fetchSourceDeployStageInfo(projectId)
    }

    func fetchSourceDeployScenarioInfo(_ projectId: Int, _ stageId: Int) async -> SourceDeployScenarioInfo {
        await deployService.fetchSourceDeployScenarioInfo(projectId, stageId)
    }

    func runSourceDeploy(_ projectId: Int, _ stageId: Int, _ scenarioId: Int) async -> SourceDeployExecResult {
        await deployService.runSourceDeploy(projectId, stageId, scenarioId)
    }
}
