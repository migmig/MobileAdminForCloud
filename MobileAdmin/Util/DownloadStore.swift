//
//  DownloadStore.swift
//  MobileAdmin
//
//  운영 기능 다운로드 파일 저장 위치 관리
//  - macOS: 사용자가 '다운로드'한 파일은 ~/Downloads (이름 중복 시 번호 부여)
//  - iOS: Caches/Ops/<category> (앱 전용, 공유 시트로 내보냄)
//  - 미리보기 캐시: Caches/Ops/<category>/... (24시간 지나면 앱 시작 시 삭제)
//

import Foundation
import Logging

enum DownloadStore {
    enum Category: String {
        case userLog
        case serverLog
        case upload
    }

    private static let logger = Logger(label: "com.migmig.MobileAdmin.DownloadStore")

    /// Caches/Ops
    static func cachesRoot(fileManager: FileManager = .default) throws -> URL {
        try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Ops", isDirectory: true)
    }

    // MARK: - 경로

    /// 사용자가 명시적으로 다운로드한 파일의 저장 위치
    static func downloadURL(category: Category, fileName: String) throws -> URL {
        let fileManager = FileManager.default
        #if os(macOS)
        let directory = try fileManager.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return uniqueURL(in: directory, fileName: fileName, fileManager: fileManager)
        #else
        let directory = try cachesRoot(fileManager: fileManager).appendingPathComponent(category.rawValue, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
        #endif
    }

    /// 미리보기 캐시 위치 — relativePath의 디렉터리 구조를 그대로 미러링한다
    /// - createDirectories: false면 경로만 계산 (존재 확인용)
    static func cacheURL(category: Category, relativePath: String, createDirectories: Bool = true) throws -> URL {
        let fileManager = FileManager.default
        var url = try cachesRoot(fileManager: fileManager).appendingPathComponent(category.rawValue, isDirectory: true)
        for segment in relativePath.split(separator: "/") {
            url.appendPathComponent(String(segment))
        }
        if createDirectories {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        return url
    }

    /// 같은 이름이 있으면 "name (1).ext", "name (2).ext" … 로 비어 있는 이름을 찾는다
    static func uniqueURL(in directory: URL, fileName: String, fileManager: FileManager = .default) -> URL {
        let candidate = directory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: candidate.path) else { return candidate }

        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        var index = 1
        while true {
            let name = ext.isEmpty ? "\(base) (\(index))" : "\(base) (\(index)).\(ext)"
            let url = directory.appendingPathComponent(name)
            if !fileManager.fileExists(atPath: url.path) {
                return url
            }
            index += 1
        }
    }

    #if os(macOS)
    /// 캐시 파일을 ~/Downloads로 복사 (이름 중복 시 번호 부여)
    static func copyToDownloads(_ source: URL) throws -> URL {
        let destination = try downloadURL(category: .upload, fileName: source.lastPathComponent)
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }
    #endif

    // MARK: - 정리

    /// 앱 시작 시 호출 — 백그라운드에서 만료 캐시 정리
    static func purgeExpiredInBackground() {
        Task.detached(priority: .background) {
            purgeExpired()
        }
    }

    /// Caches/Ops 아래에서 수정 시각이 기준보다 오래된 파일 삭제 (~/Downloads는 건드리지 않음)
    @discardableResult
    static func purgeExpired(olderThan age: TimeInterval = 86_400,
                             now: Date = Date(),
                             root: URL? = nil,
                             fileManager: FileManager = .default) -> Int {
        guard let root = root ?? (try? cachesRoot(fileManager: fileManager)),
              let enumerator = fileManager.enumerator(at: root,
                                                      includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey]) else {
            return 0
        }
        let threshold = now.addingTimeInterval(-age)
        var removed = 0
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let modified = values.contentModificationDate,
                  modified < threshold else {
                continue
            }
            if (try? fileManager.removeItem(at: url)) != nil {
                removed += 1
            }
        }
        if removed > 0 {
            logger.info("만료된 캐시 파일 \(removed)개 삭제")
        }
        return removed
    }
}
