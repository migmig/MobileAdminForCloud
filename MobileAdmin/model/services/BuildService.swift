import Foundation
import Logging

struct BuildService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.BuildService")

    func fetchSourceBuildList() async -> BuildProjects {
        do {
            let url = "\(client.baseUrl)/admin/cloud/build-project-list"
            let result: BuildProjects? = try await client.makeRequestNoRequestData(url: url)
            return result ?? BuildProjects()
        } catch {
            logger.error("fetchSourceBuildList 실패: \(error)")
        }
        return BuildProjects()
    }

    func fetchSourceBuildInfo(_ buildId: Int) async -> SourceBuildInfo? {
        do {
            let url = "\(client.baseUrl)/admin/cloud/build-project-info/\(buildId)"
            let result: SourceBuildInfo? = try await client.makeRequestNoRequestData(url: url)
            return result
        } catch {
            logger.error("fetchSourceBuildInfo 실패: \(error)")
        }
        return nil
    }

    func execSourceBuild(_ buildId: Int) async -> BuildExecResult? {
        do {
            let url = "\(client.baseUrl)/admin/cloud/exec-build-project/\(buildId)"
            let result: BuildExecResult? = try await client.makeRequestNoRequestData(url: url)
            return result
        } catch {
            logger.error("execSourceBuild 실패: \(error)")
        }
        return nil
    }

    func fetchSourceBuildHistory(_ buildId: Int) async -> SourceBuildHistoryInfo? {
        do {
            let url = "\(client.baseUrl)/admin/cloud/build-project-history-info/\(buildId)"
            let result: SourceBuildHistoryInfo? = try await client.makeRequestNoRequestData(url: url)
            return result
        } catch {
            logger.error("fetchSourceBuildHistory 실패: \(error)")
        }
        return nil
    }
}
