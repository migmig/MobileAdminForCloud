import Foundation
import Logging

struct CommitService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.CommitService")

    func fetchSourceCommitList() async -> SourceCommitInfo {
        do {
            let url = "\(client.baseUrl)/admin/cloud/commit-repository-list"
            let result: SourceCommitInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourceCommitInfo()
        } catch {
            logger.error("fetchSourceCommitList 실패: \(error)")
        }
        return SourceCommitInfo()
    }

    func fetchSourceCommitBranchList(_ repositoryName: String) async -> SourceCommitBranchInfo {
        do {
            let url = "\(client.baseUrl)/admin/cloud/commit-repository-branch-list/\(repositoryName)"
            let result: SourceCommitBranchInfo? = try await client.makeRequestNoRequestData(url: url)
            return result ?? SourceCommitBranchInfo()
        } catch {
            logger.error("fetchSourceCommitBranchList 실패: \(error)")
        }
        return SourceCommitBranchInfo()
    }
}
