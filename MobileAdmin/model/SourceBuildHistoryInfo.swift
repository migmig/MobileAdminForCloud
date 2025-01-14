
import Foundation

// MARK: - SourceBuildHistoryInfo
struct SourceBuildHistoryInfo:Codable {
   let result: SourceBuildHistoryInfoResult?
}

// MARK: - SourceBuildHistoryInfoResult
struct SourceBuildHistoryInfoResult :Codable {
   let total: Int?
   let history: [SourceBuildHistoryInfoHistory]?
}

// MARK: - SourceBuildHistoryInfoHistory
struct SourceBuildHistoryInfoHistory :Codable,Hashable {
   let projectId: Int?
   let buildId: String?
   let begin: Double?
   let end: Double?
   let userId: String?
   let status: String?
   let failedPhase: String?
}
