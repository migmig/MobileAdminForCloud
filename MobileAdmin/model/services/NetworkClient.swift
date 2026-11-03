import Foundation
import Logging

/// 네트워크 인프라 담당 클래스 - 토큰 관리, 인증된 요청 생성, 공통 요청 메서드
class NetworkClient {
    let logger = Logger(label: "com.migmig.MobileAdmin.NetworkClient")

    static var tokenExpirationDate: Date?
    static var token: String?
    private static var tokenRefreshTask: Task<Void, Error>?

    // MARK: - 공유 DateFormatter (재생성 방지)
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter
    }()

    var baseUrl: String {
        return EnvironmentConfig.baseUrl
    }

    /// 요청에 사용할 세션 (테스트에서 URLProtocol 스텁 세션 주입용)
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func setToken(token: String?) {
        NetworkClient.token = token
    }

    // MARK: - JWT 디코딩

    private func base64UrlDecode(_ input: String) -> Data? {
        var base64 = input.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")

        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
        }

        return Data(base64Encoded: base64)
    }

    private func extractExpiration(from token: String) -> Date? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            logger.warning("Invalid token format")
            return nil
        }

        guard let payloadData = base64UrlDecode(String(parts[1])) else {
            logger.warning("Failed to decode payload")
            return nil
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
               let exp = json["exp"] as? TimeInterval {
                return Date(timeIntervalSince1970: exp)
            }
        } catch {
            logger.error("Error decoding JWT payload: \(error)")
        }

        return nil
    }

    // MARK: - 토큰 관리

    /// 토큰 상태를 완전히 초기화 (환경 전환 시 호출)
    static func resetTokenState() {
        token = nil
        tokenExpirationDate = nil
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
    }

    func ensureValidToken() async throws {
        let needsRefresh = NetworkClient.token == nil ||
            (NetworkClient.tokenExpirationDate.map { $0 <= Date() } ?? true)

        guard needsRefresh else { return }

        if let existingTask = NetworkClient.tokenRefreshTask {
            try await existingTask.value
            return
        }

        let task = Task {
            defer { NetworkClient.tokenRefreshTask = nil }
            try await fetchToken()
        }
        NetworkClient.tokenRefreshTask = task
        try await task.value
    }

    func makeAuthenticatedRequest(url urlString: String) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        if let token = NetworkClient.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func fetchToken() async throws {
        logger.info("fetchToken called")
        let url = "\(baseUrl)/simpleLoginForAdmin"
        guard let adminCI = Bundle.main.object(forInfoDictionaryKey: "adminCI") as? String else {
            throw NetworkError.missingCredential
        }

        let tokenRequestData = TokenRequest(ci: adminCI)
        guard let tokenUrl = URL(string: url) else {
            throw NetworkError.invalidURL(url)
        }
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(tokenRequestData)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: url)
        }
        guard let token = httpResponse.value(forHTTPHeaderField: "Authorization") else {
            throw NetworkError.missingToken
        }
        NetworkClient.token = token
        NetworkClient.tokenExpirationDate = extractExpiration(from: token)
    }

    // MARK: - 공통 요청 메서드

    func makeRequestNoReturn<T: Codable>(
        url: String,
        requestData: T? = nil
    ) async throws {
        try await ensureValidToken()
        var request = try makeAuthenticatedRequest(url: url)

        if let requestData = requestData {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(Self.apiDateFormatter)
            request.httpBody = try encoder.encode(requestData)
        }

        _ = try await session.data(for: request)
    }

    func makeRequestNoRequestData<T: Codable>(
        url: String
    ) async throws -> T {
        try await ensureValidToken()
        let request = try makeAuthenticatedRequest(url: url)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: url)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.apiDateFormatter)
        return try decoder.decode(T.self, from: data)
    }

    func makeRequest<R: Codable, T: Codable>(
        url: String,
        requestData: R? = nil
    ) async throws -> T {
        try await ensureValidToken()
        var request = try makeAuthenticatedRequest(url: url)

        if let requestData = requestData {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(Self.apiDateFormatter)
            request.httpBody = try encoder.encode(requestData)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: url)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.apiDateFormatter)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - 운영 기능용 요청 (서버 로그 / 사용자 로그 / 업로드)
    // admin_golang 규약: 모든 요청은 POST + query string, 오류는 {"error"} 또는 {"message"} JSON,
    // 존재하지 않는 경로는 200 + SPA HTML로 응답한다.

    /// 응답에서 기대하는 Content-Type
    enum AcceptKind {
        case json
        case text
        case any
    }

    /// query 값 인코딩 허용 문자 — Go url.ParseQuery가 '+'를 공백으로 해석하므로 '+'도 인코딩한다
    private static let queryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=+#?")
        return set
    }()

    /// baseUrl + path + query → URL 문자열. 값이 nil인 query 항목은 제외한다.
    func makeURL(path: String, query: [URLQueryItem] = []) throws -> String {
        let raw = baseUrl + path
        guard var components = URLComponents(string: raw) else {
            throw NetworkError.invalidURL(raw)
        }
        let encoded = query.compactMap { item -> String? in
            guard let value = item.value else { return nil }
            let name = item.name.addingPercentEncoding(withAllowedCharacters: Self.queryValueAllowed) ?? item.name
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: Self.queryValueAllowed) ?? value
            return "\(name)=\(encodedValue)"
        }
        if !encoded.isEmpty {
            components.percentEncodedQuery = encoded.joined(separator: "&")
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL(raw)
        }
        return url.absoluteString
    }

    /// 인증 요청 후 (Data, HTTPURLResponse) 반환. 상태 코드와 Content-Type을 검증한다.
    func fetchData(
        path: String,
        query: [URLQueryItem] = [],
        accept: AcceptKind,
        timeout: TimeInterval? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let url = try makeURL(path: path, query: query)
        return try await withAuthRetry {
            var request = try makeAuthenticatedRequest(url: url)
            if let timeout { request.timeoutInterval = timeout }
            let (data, response) = try await session.data(for: request)
            let http = try validate(response, body: data, accept: accept, url: url)
            return (data, http)
        }
    }

    /// JSON 응답을 디코딩해서 반환
    func fetchJSON<T: Decodable>(path: String, query: [URLQueryItem] = [], timeout: TimeInterval? = nil) async throws -> T {
        let (data, _) = try await fetchData(path: path, query: query, accept: .json, timeout: timeout)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// 응답 바디를 메모리에 올리지 않고 디스크로 받은 뒤 destination으로 옮긴다 (기존 파일은 교체)
    @discardableResult
    func download(
        path: String,
        query: [URLQueryItem] = [],
        to destination: URL
    ) async throws -> HTTPURLResponse {
        let url = try makeURL(path: path, query: query)
        return try await withAuthRetry {
            let request = try makeAuthenticatedRequest(url: url)
            let (tempURL, response) = try await session.download(for: request)
            defer { try? FileManager.default.removeItem(at: tempURL) }

            let isSuccess = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            // 실패 응답이면 임시 파일에 오류 JSON이 들어 있다
            let body = isSuccess ? Data() : ((try? Data(contentsOf: tempURL)) ?? Data())
            let http = try validate(response, body: body, accept: .any, url: url)

            let fileManager = FileManager.default
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: tempURL, to: destination)
            return http
        }
    }

    /// 스트리밍 요청. timeout은 유휴 타임아웃(URLRequest.timeoutInterval)으로 적용된다.
    /// 실패 상태 코드면 바디를 최대 64KB까지 읽어 오류로 변환한다.
    func openStream(
        path: String,
        query: [URLQueryItem] = [],
        timeout: TimeInterval
    ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let url = try makeURL(path: path, query: query)
        return try await withAuthRetry {
            var request = try makeAuthenticatedRequest(url: url)
            request.timeoutInterval = timeout
            let (bytes, response) = try await session.bytes(for: request)
            do {
                var body = Data()
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    for try await byte in bytes {
                        body.append(byte)
                        if body.count >= 65_536 { break }
                    }
                }
                let http = try validate(response, body: body, accept: .text, url: url)
                return (bytes, http)
            } catch {
                bytes.task.cancel()
                throw error
            }
        }
    }

    // MARK: - 응답 검증 / 인증 재시도

    /// Content-Type 헤더에서 파라미터를 제외한 MIME 타입(소문자)
    static func mimeType(of response: HTTPURLResponse) -> String? {
        guard let raw = response.value(forHTTPHeaderField: "Content-Type") else { return nil }
        return raw.split(separator: ";").first?
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
    }

    /// 상태 코드 / Content-Type 검증. 실패 시 NetworkError를 던진다.
    @discardableResult
    func validate(_ response: URLResponse, body: Data, accept: AcceptKind, url: String) throws -> HTTPURLResponse {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.httpError(statusCode: -1, url: url)
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerErrorBody.self, from: body))?.text
            throw NetworkError.server(statusCode: http.statusCode, message: message, url: url)
        }
        let mime = Self.mimeType(of: http)
        if mime == "text/html" {
            throw NetworkError.unsupportedEndpoint(url: url)
        }
        switch accept {
        case .json where mime != "application/json":
            throw NetworkError.unexpectedContentType(mime, url: url)
        case .text where !(mime?.hasPrefix("text/") ?? false):
            throw NetworkError.unexpectedContentType(mime, url: url)
        default:
            return http
        }
    }

    /// 토큰 확보 후 실행하고, 401이면 토큰을 재발급받아 1회 재시도한다.
    private func withAuthRetry<T>(_ operation: () async throws -> T) async throws -> T {
        try await ensureValidToken()
        do {
            return try await operation()
        } catch NetworkError.server(statusCode: 401, _, _) {
            logger.warning("401 응답 - 토큰 재발급 후 재시도")
            NetworkClient.resetTokenState()
            try await ensureValidToken()
            return try await operation()
        }
    }
}
