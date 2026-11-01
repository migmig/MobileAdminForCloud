import Foundation
import Logging

/// 업로드 디렉터리 서비스 (/admin/upload/list|file)
/// 화면에 원인을 표시해야 하므로 기존 서비스와 달리 오류를 삼키지 않고 throw한다.
struct UploadService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.UploadService")

    func list(_ path: UploadPath) async throws -> UploadListResponse {
        do {
            return try await client.fetchJSON(path: "/admin/upload/list", query: Self.pathQuery(path))
        } catch {
            log("list", error)
            throw error
        }
    }

    /// 캐시에 있으면 재사용, 없으면 내려받아 캐시 경로를 반환한다
    func fetchFile(_ ref: UploadEntryRef) async throws -> URL {
        do {
            let destination = try DownloadStore.cacheURL(category: .upload,
                                                         relativePath: Self.cacheRelativePath(for: ref))
            if FileManager.default.fileExists(atPath: destination.path) {
                return destination
            }
            try await client.download(path: "/admin/upload/file",
                                      query: Self.pathQuery(ref.path),
                                      to: destination)
            return destination
        } catch {
            log("fetchFile", error)
            throw error
        }
    }

    /// 캐시에 이미 받아 둔 파일이 있는지
    func isCached(_ ref: UploadEntryRef) -> Bool {
        guard let url = try? DownloadStore.cacheURL(category: .upload,
                                                    relativePath: Self.cacheRelativePath(for: ref),
                                                    createDirectories: false) else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: - 경로

    static func pathQuery(_ path: UploadPath) -> [URLQueryItem] {
        path.isRoot ? [] : [URLQueryItem(name: "path", value: path.string)]
    }

    /// 캐시 경로: <디렉터리>/<modTime>-<size>/<파일명>
    /// 서버 파일이 바뀌면(수정 시각·크기 변경) 다른 경로가 되어 자동으로 다시 받는다.
    /// 파일명은 응답 헤더(RFC 5987 미적용) 대신 목록의 이름을 그대로 쓴다.
    static func cacheRelativePath(for ref: UploadEntryRef) -> String {
        ref.directory
            .appending("\(ref.entry.modTime)-\(ref.entry.size)")
            .appending(ref.entry.name)
            .string
    }

    private func log(_ method: String, _ error: Error) {
        guard !OpsError.isCancellation(error) else { return }
        logger.error("\(method) 실패: \(error)")
    }
}
