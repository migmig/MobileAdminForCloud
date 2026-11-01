//
//  UploadModels.swift
//  MobileAdmin
//
//  업로드 디렉터리 브라우저 모델 (/admin/upload/*)
//

import Foundation

// MARK: - 목록 항목 / 응답

struct UploadEntry: Codable, Hashable, Identifiable {
    let name: String
    let isDir: Bool
    let size: Int64
    /// Unix 초
    let modTime: Int64

    var id: String { name }
    var modDate: Date { Date(timeIntervalSince1970: TimeInterval(modTime)) }
    var fileKind: FileKind { FileKind.from(name: name, isDirectory: isDir) }
}

struct UploadListResponse: Codable {
    let base: String
    let path: String
    let entries: [UploadEntry]
}

// MARK: - 경로

/// "/"로 연결되는 업로드 상대 경로
struct UploadPath: Hashable {
    let segments: [String]

    static let root = UploadPath(segments: [])

    init(segments: [String]) {
        self.segments = segments
    }

    init(string: String) {
        self.segments = string.split(separator: "/").map(String.init)
    }

    var string: String { segments.joined(separator: "/") }
    var isRoot: Bool { segments.isEmpty }
    var lastName: String? { segments.last }

    var parent: UploadPath? {
        isRoot ? nil : UploadPath(segments: Array(segments.dropLast()))
    }

    func appending(_ name: String) -> UploadPath {
        UploadPath(segments: segments + [name])
    }

    /// 브레드크럼용: 루트부터 자신까지의 경로 목록 (루트 제외)
    var ancestors: [UploadPath] {
        segments.indices.map { UploadPath(segments: Array(segments[...$0])) }
    }
}

/// 선택된 업로드 파일 참조
struct UploadEntryRef: Hashable {
    let directory: UploadPath
    let entry: UploadEntry

    var path: UploadPath { directory.appending(entry.name) }
}

// MARK: - 정렬

enum UploadSort: String, CaseIterable, Identifiable {
    /// 서버 순서 (디렉터리 우선, 최신순)
    case server
    case name
    case size
    case modified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .server:   return "기본"
        case .name:     return "이름"
        case .size:     return "크기"
        case .modified: return "수정일"
        }
    }
}
