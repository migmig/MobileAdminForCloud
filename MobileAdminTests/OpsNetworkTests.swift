//
//  OpsNetworkTests.swift
//  MobileAdminTests
//
//  운영 기능 네트워킹 — URL 인코딩, 응답 검증, URLProtocol 스텁 기반 요청
//

import Testing
import Foundation
@testable import MobileAdmin

// MARK: - URLProtocol 스텁

final class OpsStubURLProtocol: URLProtocol {
    struct Reply {
        var status: Int = 200
        var headers: [String: String] = [:]
        var chunks: [Data] = []
    }

    nonisolated(unsafe) static var handler: ((URLRequest) -> Reply)?
    nonisolated(unsafe) static var requests: [URLRequest] = []

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OpsStubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        guard let handler = Self.handler, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let reply = handler(request)
        let response = HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: reply.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for chunk in reply.chunks {
            client?.urlProtocol(self, didLoad: chunk)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - 테스트

/// NetworkClient의 static 토큰 상태를 공유하는 suite들의 상위 suite — 서로 동시에 실행되지 않도록 직렬화
@Suite(.serialized)
struct SharedTokenStateTests {}

extension SharedTokenStateTests {
@Suite(.serialized)
struct OpsNetworkTests {

    let client = NetworkClient(session: OpsStubURLProtocol.session())

    init() {
        // 토큰 재발급 경로를 타지 않도록 유효한 토큰을 미리 넣어 둔다
        NetworkClient.token = "test-token"
        NetworkClient.tokenExpirationDate = Date().addingTimeInterval(3_600)
        OpsStubURLProtocol.requests = []
        OpsStubURLProtocol.handler = nil
    }

    private func query(of url: String) -> String? {
        URLComponents(string: url)?.percentEncodedQuery
    }

    // MARK: makeURL

    @Test func makeURL_encodesPlusForGo() throws {
        let url = try client.makeURL(path: "/admin/upload/file", query: [URLQueryItem(name: "path", value: "a+b.png")])
        #expect(query(of: url) == "path=a%2Bb.png")
    }

    @Test func makeURL_keepsSlashAndEncodesKoreanAndSpace() throws {
        let url = try client.makeURL(path: "/admin/upload/list", query: [URLQueryItem(name: "path", value: "app/서류 1")])
        let encoded = try #require(query(of: url))
        #expect(encoded.hasPrefix("path=app/"))
        #expect(!encoded.contains(" "))
        #expect(URLComponents(string: url)?.queryItems?.first?.value == "app/서류 1")
    }

    @Test func makeURL_encodesAmpersandAndEquals() throws {
        let url = try client.makeURL(path: "/x", query: [URLQueryItem(name: "name", value: "a&b=c#d")])
        #expect(query(of: url) == "name=a%26b%3Dc%23d")
    }

    @Test func makeURL_skipsNilAndKeepsOrder() throws {
        let url = try client.makeURL(path: "/x", query: [
            URLQueryItem(name: "lines", value: "200"),
            URLQueryItem(name: "base", value: nil),
            URLQueryItem(name: "follow", value: "true"),
        ])
        #expect(query(of: url) == "lines=200&follow=true")
    }

    @Test func makeURL_noQuery() throws {
        let url = try client.makeURL(path: "/admin/log/backend/folders")
        #expect(url.hasSuffix("/admin/log/backend/folders"))
        #expect(query(of: url) == nil)
    }

    // MARK: validate

    private func response(_ status: Int, contentType: String?) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "http://localhost/x")!, statusCode: status, httpVersion: nil,
                        headerFields: contentType.map { ["Content-Type": $0] })!
    }

    @Test func validate_htmlFallbackIsUnsupported() {
        #expect {
            try client.validate(response(200, contentType: "text/html; charset=utf-8"), body: Data(), accept: .json, url: "u")
        } throws: { error in
            if case NetworkError.unsupportedEndpoint = error { return true }
            return false
        }
    }

    @Test func validate_parsesServerErrorMessage() {
        #expect {
            try client.validate(response(404, contentType: "application/json"),
                                body: Data(#"{"error":"Log file not found"}"#.utf8), accept: .text, url: "u")
        } throws: { error in
            if case NetworkError.server(404, "Log file not found", _) = error { return true }
            return false
        }
    }

    @Test func validate_rejectsUnexpectedContentType() {
        #expect(throws: NetworkError.self) {
            try client.validate(response(200, contentType: "application/octet-stream"), body: Data(), accept: .json, url: "u")
        }
    }

    @Test func validate_acceptsTextWithCharset() throws {
        let http = try client.validate(response(200, contentType: "Text/Plain; charset=utf-8"), body: Data(), accept: .text, url: "u")
        #expect(http.statusCode == 200)
    }

    // MARK: 서비스 요청 (스텁)

    @Test func serverLogContent_parsesHeadersAndBody() async throws {
        OpsStubURLProtocol.handler = { _ in
            .init(status: 200,
                  headers: ["Content-Type": "text/plain; charset=utf-8",
                            "X-Log-File": "app.log",
                            "X-Log-Tail-Lines": "2",
                            "X-Log-Truncated": "true"],
                  chunks: [Data("... (앞부분 생략, 최근 2줄만 표시) ...\nfirst\n".utf8), Data("second\n".utf8)])
        }
        let service = ServerLogService(client: client)
        let ref = ServerLogFileRef(kind: .backend, base: .gcgfUntact, folder: "2026-10",
                                   entry: LogEntry(name: "app.log", size: 10, modTime: 0))
        let content = try await service.fetchContent(ref, tail: 500)

        #expect(content.lines.map(\.text) == ["first", "second"])
        #expect(content.truncated)
        #expect(content.tailLines == 2)

        let request = try #require(OpsStubURLProtocol.requests.last)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(request.url?.path == "/admin/log/backend/content")
        #expect(items.contains(URLQueryItem(name: "name", value: "app.log")))
        #expect(items.contains(URLQueryItem(name: "folder", value: "2026-10")))
        #expect(items.contains(URLQueryItem(name: "base", value: "gcgf-untact")))
        #expect(items.contains(URLQueryItem(name: "tail", value: "500")))
    }

    @Test func serverLogFolders_htmlFallbackThrowsUnsupported() async {
        OpsStubURLProtocol.handler = { _ in
            .init(status: 200, headers: ["Content-Type": "text/html; charset=utf-8"], chunks: [Data("<html></html>".utf8)])
        }
        let service = ServerLogService(client: client)
        await #expect {
            _ = try await service.fetchFolders(kind: .mobileid, base: nil)
        } throws: { error in
            if case NetworkError.unsupportedEndpoint = error { return true }
            return false
        }
    }

    @Test func download_writesFileToDestination() async throws {
        OpsStubURLProtocol.handler = { _ in
            .init(status: 200, headers: ["Content-Type": "application/gzip"], chunks: [Data([0x1f, 0x8b, 0x08])])
        }
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("app.log.gz")
        defer { try? FileManager.default.removeItem(at: destination.deletingLastPathComponent()) }

        try await client.download(path: "/admin/log/backend/download", to: destination)
        #expect(try Data(contentsOf: destination) == Data([0x1f, 0x8b, 0x08]))
    }

    @Test func download_failureThrowsServerMessage() async {
        OpsStubURLProtocol.handler = { _ in
            .init(status: 404, headers: ["Content-Type": "application/json"], chunks: [Data(#"{"error":"file not found"}"#.utf8)])
        }
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        await #expect {
            try await client.download(path: "/admin/upload/file", to: destination)
        } throws: { error in
            if case NetworkError.server(404, "file not found", _) = error { return true }
            return false
        }
        #expect(!FileManager.default.fileExists(atPath: destination.path))
    }

    @Test func userLogTail_assemblesLinesAcrossChunks() async throws {
        OpsStubURLProtocol.handler = { _ in
            .init(status: 200,
                  headers: ["Content-Type": "text/plain; charset=utf-8", "X-User-Log-File": "UT00000109114.log"],
                  chunks: [Data("line-1\nli".utf8), Data("ne-2\n\nline-".utf8), Data("4".utf8)])
        }
        let service = UserLogService(client: client)
        let tail = try await service.openTail(number: UserLogNumber("109114")!, lines: 200, base: .gcgfUntactStg)
        var lines: [String] = []
        for try await line in tail.lines {
            lines.append(line)
        }

        #expect(tail.fileName == "UT00000109114.log")
        #expect(lines == ["line-1", "line-2", "", "line-4"])
        let request = try #require(OpsStubURLProtocol.requests.last)
        #expect(request.url?.path == "/admin/getUserLogTail/109114")
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "lines", value: "200")))
        #expect(items.contains(URLQueryItem(name: "base", value: "gcgf-untact-stg")))
    }

    @Test func userLogTail_notFoundThrowsBeforeStreaming() async {
        OpsStubURLProtocol.handler = { _ in
            .init(status: 404, headers: ["Content-Type": "application/json"], chunks: [Data(#"{"error":"Log file not found"}"#.utf8)])
        }
        let service = UserLogService(client: client)
        await #expect {
            _ = try await service.openTail(number: UserLogNumber("1")!, lines: 200, base: nil)
        } throws: { error in
            if case NetworkError.server(404, "Log file not found", _) = error { return true }
            return false
        }
    }

    // MARK: query 구성

    @Test func serverLogQuery_baseOnlyForBackend() {
        #expect(ServerLogService.baseQuery(kind: .backend, base: .svrWasTest) == [URLQueryItem(name: "base", value: "svr-was-test")])
        #expect(ServerLogService.baseQuery(kind: .oauthResource, base: .svrWasTest).isEmpty)
        #expect(ServerLogService.folderQuery("").isEmpty)
        #expect(ServerLogService.folderQuery(nil).isEmpty)
    }

    @Test func uploadCachePath_includesModTimeAndSize() {
        let ref = UploadEntryRef(directory: UploadPath(string: "app/x"),
                                 entry: UploadEntry(name: "서류 1.pdf", isDir: false, size: 20, modTime: 100))
        #expect(UploadService.cacheRelativePath(for: ref) == "app/x/100-20/서류 1.pdf")
        #expect(UploadService.pathQuery(.root).isEmpty)
        #expect(UploadService.pathQuery(ref.path) == [URLQueryItem(name: "path", value: "app/x/서류 1.pdf")])
    }
}
}
