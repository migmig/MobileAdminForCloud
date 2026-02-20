import Foundation
import Logging

struct DeployService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.DeployService")

    func fetchSourceDeployList() async -> SourceProjectInfo {
        do {
            let url = "\(client.baseUrl)/admin/cloud/deploy-project-list"
            let result: SourceProjectInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourceProjectInfo()
        } catch {
            logger.error("fetchSourceDeployList 실패: \(error)")
        }
        return SourceProjectInfo()
    }

    func fetchSourceDeployHistoryInfo(_ projectId: Int) async -> SourceDeployHistoryInfo {
        do {
            let url = "\(client.baseUrl)/admin/cloud/deploy-project-history-list/\(projectId)"
            let result: SourceDeployHistoryInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourceDeployHistoryInfo()
        } catch {
            logger.error("fetchSourceDeployHistoryInfo 실패: \(error)")
        }
        return SourceDeployHistoryInfo()
    }

    func fetchSourceDeployStageInfo(_ projectId: Int) async -> SourceDeployStageInfo {
        do {
            let url = "\(client.baseUrl)/admin/cloud/deploy-project-stage/\(projectId)"
            let result: SourceDeployStageInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourceDeployStageInfo()
        } catch {
            logger.error("fetchSourceDeployStageInfo 실패: \(error)")
        }
        return SourceDeployStageInfo()
    }

    func fetchSourceDeployScenarioInfo(_ projectId: Int, _ stageId: Int) async -> SourceDeployScenarioInfo {
        do {
            let url = "\(client.baseUrl)/admin/cloud/deploy-project-scenario/\(projectId)/\(stageId)"
            let result: SourceDeployScenarioInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourceDeployScenarioInfo()
        } catch {
            logger.error("fetchSourceDeployScenarioInfo 실패: \(error)")
        }
        return SourceDeployScenarioInfo()
    }

    func runSourceDeploy(_ projectId: Int, _ stageId: Int, _ scenarioId: Int) async -> SourceDeployExecResult {
        do {
            let url = "\(client.baseUrl)/admin/cloud/exec-deploy/\(projectId)/\(stageId)/\(scenarioId)"
            let result: SourceDeployExecResult? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourceDeployExecResult()
        } catch {
            logger.error("runSourceDeploy 실패: \(error)")
        }
        return SourceDeployExecResult()
    }
}
