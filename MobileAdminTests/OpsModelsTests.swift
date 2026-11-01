//
//  OpsModelsTests.swift
//  MobileAdminTests
//
//  운영 기능(사용자 로그 / 서버 로그 / 업로드) 모델 테스트
//

import Testing
import Foundation
@testable import MobileAdmin

struct OpsModelsTests {

    // MARK: - 서버 응답 디코딩 (admin_golang 샘플)

    @Test func decode_logFolderList() throws {
        let json = #"{"base":"/mnt/nas/logs/svr-was-test/gcgf_untact","folders":[{"name":"2026-10","size":4096,"modTime":1761955200}]}"#
        let response = try JSONDecoder().decode(LogFolderListResponse.self, from: Data(json.utf8))
        #expect(response.base == "/mnt/nas/logs/svr-was-test/gcgf_untact")
        #expect(response.folders.count == 1)
        #expect(response.folders[0].name == "2026-10")
        #expect(response.folders[0].modDate == Date(timeIntervalSince1970: 1_761_955_200))
    }

    @Test func decode_logFileList_rootFolderIsEmptyString() throws {
        let json = #"{"base":"/mnt/nas/resource/logs","folder":"","files":[{"name":"app_2026-10-31_0.log.gz","size":182734,"modTime":1761955199}]}"#
        let response = try JSONDecoder().decode(LogFileListResponse.self, from: Data(json.utf8))
        #expect(response.folder == "")
        #expect(response.files[0].isGzip)
        #expect(response.files[0].size == 182_734)
    }

    @Test func decode_uploadList() throws {
        let json = #"{"base":"/mnt/nas/upload","path":"app/20251205_105727","entries":[{"name":"thumbs","isDir":true,"size":4096,"modTime":1764900000},{"name":"foo.png","isDir":false,"size":20480,"modTime":1764899000}]}"#
        let response = try JSONDecoder().decode(UploadListResponse.self, from: Data(json.utf8))
        #expect(response.entries.count == 2)
        #expect(response.entries[0].isDir)
        #expect(response.entries[0].fileKind == .folder)
        #expect(response.entries[1].fileKind == .image)
    }

    @Test func decode_serverErrorBody_bothShapes() throws {
        let handler = try JSONDecoder().decode(ServerErrorBody.self, from: Data(#"{"error":"Log file not found"}"#.utf8))
        let middleware = try JSONDecoder().decode(ServerErrorBody.self, from: Data(#"{"status":"error","message":"Invalid or expired token"}"#.utf8))
        #expect(handler.text == "Log file not found")
        #expect(middleware.text == "Invalid or expired token")
    }

    // MARK: - UserLogNumber

    @Test(arguments: [
        ("109114", 109114),
        ("UT00000109114", 109114),
        (" ut12 ", 12),
        ("00001000", 1000),
    ])
    func userLogNumber_valid(raw: String, expected: Int) {
        #expect(UserLogNumber(raw)?.value == expected)
    }

    @Test(arguments: ["", "0", "-1", "12a", "UT", "1 2", "１２", "99999999999999999999999"])
    func userLogNumber_invalid(raw: String) {
        #expect(UserLogNumber(raw) == nil)
    }

    @Test func userLogNumber_fileName() {
        #expect(UserLogNumber("14")?.fileName == "UT00000000014.log")
        #expect(UserLogNumber("109114")?.fileName == "UT00000109114.log")
    }

    // MARK: - UploadPath

    @Test func uploadPath_operations() {
        let path = UploadPath(string: "/app/20251205_105727/")
        #expect(path.segments == ["app", "20251205_105727"])
        #expect(path.string == "app/20251205_105727")
        #expect(path.lastName == "20251205_105727")
        #expect(path.parent == UploadPath(string: "app"))
        #expect(path.appending("thumbs").string == "app/20251205_105727/thumbs")
        #expect(path.ancestors.map(\.string) == ["app", "app/20251205_105727"])
    }

    @Test func uploadPath_root() {
        #expect(UploadPath.root.isRoot)
        #expect(UploadPath.root.parent == nil)
        #expect(UploadPath.root.string == "")
        #expect(UploadPath(string: "").isRoot)
        #expect(UploadPath.root.ancestors.isEmpty)
    }

    // MARK: - FileKind

    @Test func fileKind_byExtension() {
        #expect(FileKind.from(name: "a.PNG", isDirectory: false) == .image)
        #expect(FileKind.from(name: "scan.pdf", isDirectory: false) == .pdf)
        #expect(FileKind.from(name: "app.log", isDirectory: false) == .text)
        #expect(FileKind.from(name: "app.log.gz", isDirectory: false) == .archive)
        #expect(FileKind.from(name: "clip.mov", isDirectory: false) == .video)
        #expect(FileKind.from(name: "noext", isDirectory: false) == .other)
        #expect(FileKind.from(name: "dir.png", isDirectory: true) == .folder)
        #expect(!FileKind.archive.isPreviewable)
        #expect(FileKind.pdf.isPreviewable)
    }

    // MARK: - ServerLogFileRef / NAS 폴백

    @Test func serverLogFileRef_dropsBaseForNonBackend() {
        let entry = LogEntry(name: "a.log", size: 1, modTime: 0)
        let oauth = ServerLogFileRef(kind: .oauthAuth, base: .gcgfUntact, folder: "", entry: entry)
        #expect(oauth.base == nil)
        #expect(oauth.folder == nil)
        #expect(oauth.displayPath == "a.log")

        let backend = ServerLogFileRef(kind: .backend, base: .gcgfUntact, folder: "2026-10", entry: entry)
        #expect(backend.base == .gcgfUntact)
        #expect(backend.displayPath == "2026-10/a.log")
    }

    @Test func nasLogBase_localFallbackDetection() {
        #expect(!NasLogBase.isLocalFallback("/mnt/nas/logs/mobileid"))
        #expect(NasLogBase.isLocalFallback("/app/.nas/logs/mobileid"))
    }

    // MARK: - LogContent.parse

    @Test func logContent_removesTruncationMarker() {
        let body = "... (앞부분 생략, 최근 2줄만 표시) ...\nline-2\nline-3\n"
        let content = LogContent.parse(Data(body.utf8), fileName: "app.log", headerTailLines: 2, truncated: true)
        #expect(content.lines.map(\.text) == ["line-2", "line-3"])
        #expect(content.lines.map(\.id) == [0, 1])
        #expect(content.truncated)
        #expect(content.tailLines == 2)
    }

    @Test func logContent_keepsFirstLineWhenNotTruncated() {
        let body = "... (앞부분 생략 처럼 보이는 일반 줄\nb"
        let content = LogContent.parse(Data(body.utf8), fileName: "a", headerTailLines: nil, truncated: false)
        #expect(content.lines.count == 2)
        #expect(content.tailLines == 2)
    }

    @Test func logContent_preservesEmptyLinesAndStripsCR() {
        let content = LogContent.parse(Data("a\r\n\r\nb\n".utf8), fileName: "a", headerTailLines: nil, truncated: false)
        #expect(content.lines.map(\.text) == ["a", "", "b"])
    }

    @Test func logContent_emptyBody() {
        let content = LogContent.parse(Data(), fileName: "a", headerTailLines: 0, truncated: false)
        #expect(content.lines.isEmpty)
    }
}
