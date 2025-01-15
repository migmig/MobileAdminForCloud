import Foundation

// MARK: - SourceBuildInfo
struct SourceBuildInfo: Codable {
    let result: SourceBuildInfoResult?
}

// MARK: - Result
struct SourceBuildInfoResult: Codable {
    let id: Int?
    let name: String?
    let description: String?
    let created: SourceBuildInfoCreated?
    let source: SourceBuildInfoSource?
    let env: SourceBuildInfoEnv?
    let cmd: SourceBuildInfoCmd?
    let artifact: SourceBuildInfoArtifact?
    let cache: SourceBuildInfoCache?
    let linked: SourceBuildInfoLinked?
    let lastBuild: SourceBuildInfoLastBuild?
}

// MARK: - Artifact
struct SourceBuildInfoArtifact: Codable {
    let use: Bool?
    let path: [String]?
    let storage: SourceBuildInfoStorage?
    let backup: Bool?
}

// MARK: - Storage
struct SourceBuildInfoStorage: Codable {
    let bucket, path, filename: String?
}

// MARK: - Cache
struct SourceBuildInfoCache: Codable {
    let use: Bool?
}

// MARK: - Cmd
struct SourceBuildInfoCmd: Codable {
    let pre, build, post: [String]?
    let dockerbuild: SourceBuildInfoCache?
}

// MARK: - Created
struct SourceBuildInfoCreated: Codable {
    let timestamp: Int?
    let user: String?
}

// MARK: - Env
struct SourceBuildInfoEnv: Codable {
    let timeout: Int?
    let envVars: [SourceBuildInfoEnvVar]?
    let compute: SourceBuildInfoCompute?
    let platform: SourceBuildInfoPlatform?
    let docker: SourceBuildInfoCache?
}

// MARK: - Compute
struct SourceBuildInfoCompute: Codable {
    let id, cpu, mem: Int?
}

// MARK: - EnvVar
struct SourceBuildInfoEnvVar: Codable {
    let key, value: String?
}

// MARK: - Platform
struct SourceBuildInfoPlatform: Codable {
    let type: String?
    let config: SourceBuildInfoPlatformConfig?
}

// MARK: - PlatformConfig
struct SourceBuildInfoPlatformConfig: Codable {
    let os: SourceBuildInfoOS?
    let runtime: SourceBuildInfoRuntime?
}

// MARK: - OS
struct SourceBuildInfoOS: Codable {
    let id: Int?
    let name, version, archi: String?
}

// MARK: - Runtime
struct SourceBuildInfoRuntime: Codable {
    let id: Int?
    let name: String?
    let version: SourceBuildInfoVersion?
}

// MARK: - Version
struct SourceBuildInfoVersion: Codable {
    let id: Int?
    let name: String?
}

// MARK: - LastBuild
struct SourceBuildInfoLastBuild: Codable {
    let id: String?
    let timestamp: Double?
    let status: String?
}

// MARK: - Linked
struct SourceBuildInfoLinked: Codable {
    let fileSafer, cloudLogAnalytics: Bool?

    enum CodingKeys: String, CodingKey {
        case fileSafer = "FileSafer"
        case cloudLogAnalytics = "CloudLogAnalytics"
    }
}

// MARK: - Source
struct SourceBuildInfoSource: Codable {
    let type: String?
    let config: SourceBuildInfoSourceConfig?
}

// MARK: - SourceConfig
struct SourceBuildInfoSourceConfig: Codable {
    let repository, branch: String?
}


struct BuildExecResult: Codable{ 
    let result: BuildExecResultInfo
}


struct BuildExecResultInfo: Codable{
    let projectId: Int
    let buildId: String
}
