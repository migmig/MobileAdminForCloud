//
//  OpsCommon.swift
//  MobileAdmin
//
//  운영 기능(사용자 로그 / 서버 로그 / 업로드) 공통 모델
//

import Foundation

// MARK: - NAS 로그 경로 키

/// admin_golang의 `base` query 값 (사용자 로그 / Backend 로그 공용)
enum NasLogBase: String, CaseIterable, Identifiable, Codable, Hashable {
    case svrWasTest = "svr-was-test"
    case gcgfUntact = "gcgf-untact"
    case gcgfUntactStg = "gcgf-untact-stg"

    var id: String { rawValue }
    var title: String { rawValue }

    /// 서버 응답의 base 경로가 NAS가 아니면 로컬 폴백 디렉터리를 보고 있는 것
    static func isLocalFallback(_ basePath: String) -> Bool {
        !basePath.hasPrefix("/mnt/nas/")
    }
}

// MARK: - 서버 오류 바디

/// 서버 오류 바디 — 핸들러는 {"error"}, JWT 미들웨어는 {"status","message"} 형식
struct ServerErrorBody: Decodable {
    let error: String?
    let message: String?

    var text: String? { error ?? message }
}

// MARK: - 운영 기능 오류

enum OpsError: LocalizedError {
    case invalidUserNumber(String)

    var errorDescription: String? {
        switch self {
        case .invalidUserNumber(let raw):
            return "잘못된 사용자 번호입니다: \(raw)"
        }
    }

    /// 취소로 인한 오류인지 (사용자에게 표시하지 않음)
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}

// MARK: - 파일 종류

enum FileKind: Equatable {
    case folder, image, pdf, text, video, archive, other

    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "heif", "webp", "bmp", "tif", "tiff", "svg", "avif"]
    private static let textExtensions: Set<String> = ["log", "txt", "json", "xml", "csv", "md", "yaml", "yml", "conf", "ini", "env",
                                                      "properties", "toml", "sql", "sh", "go", "java", "kt", "swift", "py", "rb",
                                                      "rs", "js", "ts", "html", "htm", "css"]
    private static let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv", "webm"]
    private static let archiveExtensions: Set<String> = ["gz", "zip", "tar", "tgz", "7z", "rar"]

    static func from(name: String, isDirectory: Bool) -> FileKind {
        if isDirectory { return .folder }
        let ext = (name as NSString).pathExtension.lowercased()
        if imageExtensions.contains(ext) { return .image }
        if ext == "pdf" { return .pdf }
        if textExtensions.contains(ext) { return .text }
        if videoExtensions.contains(ext) { return .video }
        if archiveExtensions.contains(ext) { return .archive }
        return .other
    }

    var systemImage: String {
        switch self {
        case .folder:  return "folder.fill"
        case .image:   return "photo"
        case .pdf:     return "doc.richtext"
        case .text:    return "doc.text"
        case .video:   return "film"
        case .archive: return "doc.zipper"
        case .other:   return "doc"
        }
    }

    var title: String {
        switch self {
        case .folder:  return "폴더"
        case .image:   return "이미지"
        case .pdf:     return "PDF"
        case .text:    return "텍스트"
        case .video:   return "동영상"
        case .archive: return "압축 파일"
        case .other:   return "기타"
        }
    }

    /// Quick Look으로 내용을 볼 수 있는 종류 (압축 파일은 제외)
    var isPreviewable: Bool {
        self != .archive && self != .folder
    }
}
