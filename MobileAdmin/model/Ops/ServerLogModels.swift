//
//  ServerLogModels.swift
//  MobileAdmin
//
//  서버 로그 뷰어 모델 (/admin/log/{kind}/*)
//

import Foundation

// MARK: - 로그 종류

enum ServerLogKind: String, CaseIterable, Identifiable, Hashable {
    case backend
    case oauthResource
    case oauthAuth
    case mobileid

    var id: String { rawValue }

    var pathPrefix: String {
        switch self {
        case .backend:       return "/admin/log/backend"
        case .oauthResource: return "/admin/log/oauth/resource"
        case .oauthAuth:     return "/admin/log/oauth/auth"
        case .mobileid:      return "/admin/log/mobileid"
        }
    }

    var title: String {
        switch self {
        case .backend:       return "Backend"
        case .oauthResource: return "OAuth Resource"
        case .oauthAuth:     return "OAuth Auth"
        case .mobileid:      return "MobileID"
        }
    }

    var summary: String {
        switch self {
        case .backend:       return "백엔드 애플리케이션 로그"
        case .oauthResource: return "OAuth 리소스 서버 로그"
        case .oauthAuth:     return "OAuth 인가 서버 로그"
        case .mobileid:      return "모바일 신분증 연동 로그"
        }
    }

    var systemImage: String {
        switch self {
        case .backend:       return "server.rack"
        case .oauthResource: return "key.horizontal"
        case .oauthAuth:     return "person.badge.key"
        case .mobileid:      return "person.text.rectangle"
        }
    }

    /// base query는 backend만 지원 (나머지는 서버가 무시)
    var supportsBase: Bool { self == .backend }

    static let defaultBase: NasLogBase = .svrWasTest
}

// MARK: - 목록 항목 / 응답

/// 폴더·파일 공통 항목 (isDir 없음 — 폴더와 파일은 서로 다른 엔드포인트에서 온다)
struct LogEntry: Codable, Hashable, Identifiable {
    let name: String
    let size: Int64
    /// Unix 초
    let modTime: Int64

    var id: String { name }
    var modDate: Date { Date(timeIntervalSince1970: TimeInterval(modTime)) }
    var isGzip: Bool { name.lowercased().hasSuffix(".gz") }
}

struct LogFolderListResponse: Codable {
    let base: String
    let folders: [LogEntry]
}

struct LogFileListResponse: Codable {
    let base: String
    let folder: String
    let files: [LogEntry]
}

// MARK: - 파일 참조

/// macOS 선택 상태 / iOS 내비게이션 값으로 쓰는 로그 파일 참조
struct ServerLogFileRef: Hashable {
    let kind: ServerLogKind
    /// backend가 아니면 nil
    let base: NasLogBase?
    /// nil = 루트
    let folder: String?
    let entry: LogEntry

    init(kind: ServerLogKind, base: NasLogBase?, folder: String?, entry: LogEntry) {
        self.kind = kind
        self.base = kind.supportsBase ? base : nil
        self.folder = (folder?.isEmpty ?? true) ? nil : folder
        self.entry = entry
    }

    /// 화면 표시용 경로 (예: "2026-10/app.log")
    var displayPath: String {
        if let folder { return "\(folder)/\(entry.name)" }
        return entry.name
    }
}
