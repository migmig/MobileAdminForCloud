import Foundation
import Logging

struct PipelineService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.PipelineService")

    func fetchSourcePipelineList() async -> SourceProjectInfo {
        do {
            let url = "\(client.baseUrl)/admin/cloud/pipeline-project-list"
            let result: SourceProjectInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourceProjectInfo()
        } catch {
            logger.error("fetchSourcePipelineList 실패: \(error)")
        }
        return SourceProjectInfo()
    }

    func fetchSourcePipelineHistoryInfo(_ projectId: Int) async -> SourcePipelineHistoryInfo {
        do {
            let url = "\(client.baseUrl)/admin/cloud/pipeline-history-info/\(projectId)"
            let result: SourcePipelineHistoryInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourcePipelineHistoryInfo()
        } catch {
            logger.error("fetchSourcePipelineHistoryInfo 실패: \(error)")
        }
        return SourcePipelineHistoryInfo()
    }

    func runSourcePipeline(_ projectId: Int) async -> SourcePipelineExecResult {
        do {
            let url = "\(client.baseUrl)/admin/cloud/exec-pipeline-project/\(projectId)"
            let result: SourcePipelineExecResult? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourcePipelineExecResult()
        } catch {
            logger.error("runSourcePipeline 실패: \(error)")
        }
        return SourcePipelineExecResult()
    }

    func cancelSourcePipeline(_ projectId: Int, _ historyId: Int) async -> SourcePipelineExecResult {
        do {
            let url = "\(client.baseUrl)/admin/cloud/cancel-pipeline-project/\(projectId)/\(historyId)"
            let result: SourcePipelineExecResult? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourcePipelineExecResult()
        } catch {
            logger.error("cancelSourcePipeline 실패: \(error)")
        }
        return SourcePipelineExecResult()
    }
}
