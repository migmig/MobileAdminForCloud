import Foundation
import Logging

/// 서버 로그 서비스 (/admin/log/{kind}/folders|files|content|download)
/// 화면에 원인을 표시해야 하므로 기존 서비스와 달리 오류를 삼키지 않고 throw한다.
struct ServerLogService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.ServerLogService")

    /// tail 선택지 (서버 기본 1000, 최대 10000)
    static let tailOptions = [200, 500, 1_000, 5_000, 10_000]
    static let defaultTail = 1_000
    /// 큰 .gz 파일은 서버가 전체를 풀어서 스캔하므로 기본(60초)보다 길게
    static let contentTimeout: TimeInterval = 120

    func fetchFolders(kind: ServerLogKind, base: NasLogBase?) async throws -> LogFolderListResponse {
        do {
            return try await client.fetchJSON(path: "\(kind.pathPrefix)/folders",
                                              query: Self.baseQuery(kind: kind, base: base))
        } catch {
            log("fetchFolders", error)
            throw error
        }
    }

    func fetchFiles(kind: ServerLogKind, base: NasLogBase?, folder: String?) async throws -> LogFileListResponse {
        do {
            return try await client.fetchJSON(path: "\(kind.pathPrefix)/files",
                                              query: Self.folderQuery(folder) + Self.baseQuery(kind: kind, base: base))
        } catch {
            log("fetchFiles", error)
            throw error
        }
    }

    func fetchContent(_ ref: ServerLogFileRef, tail: Int) async throws -> LogContent {
        do {
            let (data, response) = try await client.fetchData(
                path: "\(ref.kind.pathPrefix)/content",
                query: Self.fileQuery(ref) + [URLQueryItem(name: "tail", value: String(tail))],
                accept: .text,
                timeout: Self.contentTimeout
            )
            let fileName = response.value(forHTTPHeaderField: "X-Log-File") ?? ref.entry.name
            let tailLines = response.value(forHTTPHeaderField: "X-Log-Tail-Lines").flatMap { Int($0) }
            let truncated = response.value(forHTTPHeaderField: "X-Log-Truncated")?.lowercased() == "true"
            // 최대 1만 줄 분할은 메인 스레드 밖에서
            return await Task.detached(priority: .userInitiated) {
                LogContent.parse(data, fileName: fileName, headerTailLines: tailLines, truncated: truncated)
            }.value
        } catch {
            log("fetchContent", error)
            throw error
        }
    }

    /// 원본 파일 다운로드 (.gz도 그대로)
    func download(_ ref: ServerLogFileRef) async throws -> URL {
        do {
            let destination = try DownloadStore.downloadURL(category: .serverLog, fileName: ref.entry.name)
            try await client.download(path: "\(ref.kind.pathPrefix)/download",
                                      query: Self.fileQuery(ref),
                                      to: destination)
            return destination
        } catch {
            log("download", error)
            throw error
        }
    }

    // MARK: - query 구성

    /// base는 backend만 전송
    static func baseQuery(kind: ServerLogKind, base: NasLogBase?) -> [URLQueryItem] {
        guard kind.supportsBase, let base else { return [] }
        return [URLQueryItem(name: "base", value: base.rawValue)]
    }

    /// 빈 폴더(루트)는 생략
    static func folderQuery(_ folder: String?) -> [URLQueryItem] {
        guard let folder, !folder.isEmpty else { return [] }
        return [URLQueryItem(name: "folder", value: folder)]
    }

    static func fileQuery(_ ref: ServerLogFileRef) -> [URLQueryItem] {
        [URLQueryItem(name: "name", value: ref.entry.name)]
            + folderQuery(ref.folder)
            + baseQuery(kind: ref.kind, base: ref.base)
    }

    private func log(_ method: String, _ error: Error) {
        guard !OpsError.isCancellation(error) else { return }
        logger.error("\(method) 실패: \(error)")
    }
}
