//
//  OpsStateTests.swift
//  MobileAdminTests
//
//  운영 기능 상태 로직 — tail 모델, 업로드 정렬, 다운로드 저장소, 검색, 오류 매핑
//

import Testing
import Foundation
@testable import MobileAdmin

// MARK: - UserLogTailModel

@MainActor
struct UserLogTailModelTests {

    private let target = UserLogTarget(number: UserLogNumber("109114")!, base: nil, initialLines: 200)

    /// 조건이 참이 될 때까지 대기 (최대 2초)
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test func streamsLinesAndDropsOverLimit() async {
        let model = UserLogTailModel(maxLines: 3, flushInterval: .milliseconds(10)) { _ in
            let stream = AsyncThrowingStream<String, Error> { continuation in
                (1...5).forEach { continuation.yield("line-\($0)") }
                continuation.finish()
            }
            return ("UT00000109114.log", stream)
        }
        model.start(target)
        await waitUntil { model.status == .stopped(.ended) }

        #expect(model.status == .stopped(.ended))
        #expect(model.fileName == "UT00000109114.log")
        #expect(model.lines.map(\.text) == ["line-3", "line-4", "line-5"])
        #expect(model.lines.map(\.id) == [2, 3, 4])
        #expect(model.droppedLineCount == 2)
        #expect(model.lastReceivedAt != nil)
    }

    @Test func openFailureSetsFailedStatus() async {
        let model = UserLogTailModel(flushInterval: .milliseconds(10)) { _ in
            throw NetworkError.server(statusCode: 404, message: "Log file not found", url: "u")
        }
        model.start(target)
        await waitUntil { if case .failed = model.status { return true }; return false }

        guard case .failed(let message) = model.status else {
            Issue.record("expected failed, got \(model.status)")
            return
        }
        #expect(message.contains("Log file not found"))
        #expect(message.contains("사용자 번호와 로그 경로를 확인하세요"))
    }

    @Test func stopTerminatesStream() async {
        let terminated = Locked(false)
        let model = UserLogTailModel(flushInterval: .milliseconds(10)) { _ in
            let stream = AsyncThrowingStream<String, Error> { continuation in
                continuation.yield("first")
                continuation.onTermination = { _ in terminated.set(true) }
                // finish 하지 않음 — 계속 열려 있는 스트림
            }
            return (nil, stream)
        }
        model.start(target)
        await waitUntil { model.lines.count == 1 }
        #expect(model.status == .streaming)

        model.stop()
        #expect(model.status == .stopped(.user))
        await waitUntil { terminated.value }
        #expect(terminated.value)
    }

    @Test func restartClearsBuffer() async {
        let model = UserLogTailModel(flushInterval: .milliseconds(10)) { _ in
            let stream = AsyncThrowingStream<String, Error> { continuation in
                continuation.yield("a")
                continuation.finish()
            }
            return (nil, stream)
        }
        model.start(target)
        await waitUntil { model.status == .stopped(.ended) }
        #expect(model.lines.count == 1)

        model.reconnect()
        #expect(model.lines.isEmpty)
        #expect(model.status == .connecting)
        await waitUntil { model.status == .stopped(.ended) }
        #expect(model.lines.map(\.id) == [0])
    }
}

/// 테스트용 스레드 안전 값 상자
final class Locked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value
    init(_ value: Value) { stored = value }
    var value: Value { lock.lock(); defer { lock.unlock() }; return stored }
    func set(_ value: Value) { lock.lock(); stored = value; lock.unlock() }
}

// MARK: - 업로드 정렬

struct UploadArrangeTests {

    private let entries = [
        UploadEntry(name: "b.png", isDir: false, size: 300, modTime: 30),
        UploadEntry(name: "docs", isDir: true, size: 4096, modTime: 10),
        UploadEntry(name: "a10.pdf", isDir: false, size: 100, modTime: 20),
        UploadEntry(name: "a2.pdf", isDir: false, size: 200, modTime: 20),
        UploadEntry(name: "dir", isDir: true, size: 4096, modTime: 50),
    ]

    @Test func serverOrderKeptWithoutSort() {
        let result = UploadBrowserModel.arrange(entries, filter: "", sort: .server, ascending: true)
        #expect(result.map(\.name) == entries.map(\.name))
    }

    @Test func nameAscendingUsesNaturalOrderAndDirectoriesFirst() {
        let result = UploadBrowserModel.arrange(entries, filter: "", sort: .name, ascending: true)
        #expect(result.map(\.name) == ["dir", "docs", "a2.pdf", "a10.pdf", "b.png"])
    }

    @Test func koreanNamesSortInGanadaOrder() {
        let korean = ["다.png", "가.png", "나.png"].map { UploadEntry(name: $0, isDir: false, size: 1, modTime: 1) }
        let result = UploadBrowserModel.arrange(korean, filter: "", sort: .name, ascending: true)
        #expect(result.map(\.name) == ["가.png", "나.png", "다.png"])
    }

    @Test func sizeDescendingKeepsDirectoriesFirst() {
        let result = UploadBrowserModel.arrange(entries, filter: "", sort: .size, ascending: false)
        #expect(result.map(\.name) == ["dir", "docs", "b.png", "a2.pdf", "a10.pdf"])
    }

    @Test func modifiedTieBreaksByName() {
        let result = UploadBrowserModel.arrange(entries, filter: "", sort: .modified, ascending: false)
        #expect(result.map(\.name) == ["dir", "docs", "b.png", "a2.pdf", "a10.pdf"])
    }

    @Test func filterIsCaseInsensitive() {
        let result = UploadBrowserModel.arrange(entries, filter: " PDF ", sort: .server, ascending: false)
        #expect(result.map(\.name) == ["a10.pdf", "a2.pdf"])
    }
}

// MARK: - DownloadStore

struct DownloadStoreTests {

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func uniqueURL_appendsNumber() throws {
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(DownloadStore.uniqueURL(in: directory, fileName: "app.log").lastPathComponent == "app.log")
        FileManager.default.createFile(atPath: directory.appendingPathComponent("app.log").path, contents: Data())
        #expect(DownloadStore.uniqueURL(in: directory, fileName: "app.log").lastPathComponent == "app (1).log")
        FileManager.default.createFile(atPath: directory.appendingPathComponent("app (1).log").path, contents: Data())
        #expect(DownloadStore.uniqueURL(in: directory, fileName: "app.log").lastPathComponent == "app (2).log")
        FileManager.default.createFile(atPath: directory.appendingPathComponent("README").path, contents: Data())
        #expect(DownloadStore.uniqueURL(in: directory, fileName: "README").lastPathComponent == "README (1)")
    }

    @Test func purgeExpired_removesOnlyOldFiles() throws {
        let root = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let nested = root.appendingPathComponent("upload/app/1-2", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)

        let now = Date()
        let old = nested.appendingPathComponent("old.png")
        let fresh = root.appendingPathComponent("fresh.log")
        FileManager.default.createFile(atPath: old.path, contents: Data([1]))
        FileManager.default.createFile(atPath: fresh.path, contents: Data([1]))
        try FileManager.default.setAttributes([.modificationDate: now.addingTimeInterval(-90_000)], ofItemAtPath: old.path)
        try FileManager.default.setAttributes([.modificationDate: now.addingTimeInterval(-60)], ofItemAtPath: fresh.path)

        let removed = DownloadStore.purgeExpired(olderThan: 86_400, now: now, root: root)
        #expect(removed == 1)
        #expect(!FileManager.default.fileExists(atPath: old.path))
        #expect(FileManager.default.fileExists(atPath: fresh.path))
    }
}

// MARK: - 로그 검색

struct LogSearchStateTests {

    private let lines = ["INFO start", "ERROR boom", "info ok", "Error again"].enumerated().map { LogLine(id: $0.offset, text: $0.element) }

    @Test func recomputeFindsCaseInsensitiveMatchesAndStartsAtLast() {
        var state = LogSearchState()
        state.query = "error"
        state.recompute(in: lines)
        #expect(state.matches == [1, 3])
        #expect(state.currentID == 3)
        #expect(state.positionText == "2/2")
    }

    @Test func nextAndPreviousWrapAround() {
        var state = LogSearchState()
        state.query = "info"
        state.recompute(in: lines)
        #expect(state.currentID == 2)
        state.next()
        #expect(state.currentID == 0)
        state.previous()
        #expect(state.currentID == 2)
    }

    @Test func keepsCurrentMatchWhenLinesAppended() {
        var state = LogSearchState()
        state.query = "error"
        state.recompute(in: lines)
        state.previous()
        #expect(state.currentID == 1)
        state.recompute(in: lines + [LogLine(id: 4, text: "ERROR new")])
        #expect(state.currentID == 1)
        #expect(state.matches == [1, 3, 4])
    }

    @Test func emptyQueryClearsMatches() {
        var state = LogSearchState()
        state.recompute(in: lines)
        #expect(state.matches.isEmpty)
        #expect(state.currentID == nil)
        #expect(state.positionText == "0/0")
    }
}

// MARK: - 오류 표시 매핑

struct OpsErrorPresentationTests {

    @Test func unsupportedEndpoint() {
        let presentation = OpsErrorPresentation(error: NetworkError.unsupportedEndpoint(url: "u"))
        #expect(presentation.title == "지원하지 않는 서버")
    }

    @Test func notFoundAppendsHint() {
        let presentation = OpsErrorPresentation(error: NetworkError.server(statusCode: 404, message: "Log file not found", url: "u"),
                                                notFoundHint: "번호를 확인하세요.")
        #expect(presentation.title == "찾을 수 없음")
        #expect(presentation.message == "Log file not found\n번호를 확인하세요.")
    }

    @Test func serverErrorWithoutMessage() {
        let presentation = OpsErrorPresentation(error: NetworkError.server(statusCode: 500, message: nil, url: "u"))
        #expect(presentation.title == "서버 오류")
        #expect(presentation.message == "HTTP 오류 500")
    }

    @Test func urlErrorTimeout() {
        let presentation = OpsErrorPresentation(error: URLError(.timedOut))
        #expect(presentation.title == "응답 시간 초과")
    }

    @Test func cancellationDetection() {
        #expect(OpsError.isCancellation(CancellationError()))
        #expect(OpsError.isCancellation(URLError(.cancelled)))
        #expect(!OpsError.isCancellation(URLError(.timedOut)))
    }
}
