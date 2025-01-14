// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sourceBuildInfo = try? JSONDecoder().decode(SourceBuildInfo.self, from: jsonData)

import Foundation

// MARK: - SourceBuildInfo
struct SourceBuildInfo: Codable {
    let result: SourceBuildInfoResult?
}

// MARK: - Result
struct SourceBuildInfoResult: Codable {
    let id: Int?
    let name, description: String?
    let created: Created?
    let source: Source?
    let env: Env?
    let cmd: Cmd?
    let artifact: Artifact?
    let cache: Cache?
    let linked: Linked?
    let lastBuild: LastBuild?
}

// MARK: - Artifact
struct Artifact: Codable {
    let use: Bool?
    let path: [String]?
    let storage: Storage?
    let backup: Bool?
}

// MARK: - Storage
struct Storage: Codable {
    let bucket, path, filename: String?
}

// MARK: - Cache
struct Cache: Codable {
    let use: Bool?
}

// MARK: - Cmd
struct Cmd: Codable {
    let pre, build, post: [String]?
    let dockerbuild: Cache?
}

// MARK: - Created
struct Created: Codable {
    let timestamp: Int?
    let user: String?
}

// MARK: - Env
struct Env: Codable {
    let timeout: Int?
    let envVars: [EnvVar]?
    let compute: Compute?
    let platform: Platform?
    let docker: Cache?
}

// MARK: - Compute
struct Compute: Codable {
    let id, cpu, mem: Int?
}

// MARK: - EnvVar
struct EnvVar: Codable {
    let key, value: String?
}

// MARK: - Platform
struct Platform: Codable {
    let type: String?
    let config: PlatformConfig?
}

// MARK: - PlatformConfig
struct PlatformConfig: Codable {
    let os: OS?
    let runtime: Runtime?
}

// MARK: - OS
struct OS: Codable {
    let id: Int?
    let name, version, archi: String?
}

// MARK: - Runtime
struct Runtime: Codable {
    let id: Int?
    let name: String?
    let version: Version?
}

// MARK: - Version
struct Version: Codable {
    let id: Int?
    let name: String?
}

// MARK: - LastBuild
struct LastBuild: Codable {
    let id: String?
    let timestamp: Double?
    let status: String?
}

// MARK: - Linked
struct Linked: Codable {
    let fileSafer, cloudLogAnalytics: Bool?

    enum CodingKeys: String, CodingKey {
        case fileSafer = "FileSafer"
        case cloudLogAnalytics = "CloudLogAnalytics"
    }
}

// MARK: - Source
struct Source: Codable {
    let type: String?
    let config: SourceConfig?
}

// MARK: - SourceConfig
struct SourceConfig: Codable {
    let repository, branch: String?
}


struct BuildExecResult: Codable{ 
    let result: BuildExecResultInfo
}


struct BuildExecResultInfo: Codable{
    let projectId: Int
    let buildId: String
}
