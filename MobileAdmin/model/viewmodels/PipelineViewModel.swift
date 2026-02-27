import Foundation

@MainActor
class PipelineViewModel: ObservableObject {
    @Published var sourcePipelineList: [SourceInfoProjectInfo] = []
    @Published var sourcePipelineHistoryList: [SourcePipelineHistoryInfoHistoryList] = []

    private let pipelineService = PipelineService(client: NetworkClient())

    func fetchSourcePipelineList() async {
        let result = await pipelineService.fetchSourcePipelineList()
        sourcePipelineList = result.result.projectList.sorted { $0.id < $1.id }
    }

    func fetchSourcePipelineHistoryInfo(_ projectId: Int) async -> SourcePipelineHistoryInfo {
        await pipelineService.fetchSourcePipelineHistoryInfo(projectId)
    }

    func runSourcePipeline(_ projectId: Int) async -> SourcePipelineExecResult {
        await pipelineService.runSourcePipeline(projectId)
    }

    func cancelSourcePipeline(_ projectId: Int, _ historyId: Int) async -> SourcePipelineExecResult {
        await pipelineService.cancelSourcePipeline(projectId, historyId)
    }
}
