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

        let (_, response) = try await URLSession.shared.data(for: request)

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

        _ = try await URLSession.shared.data(for: request)
    }

    func makeRequestNoRequestData<T: Codable>(
        url: String
    ) async throws -> T {
        try await ensureValidToken()
        let request = try makeAuthenticatedRequest(url: url)

        let (data, response) = try await URLSession.shared.data(for: request)

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

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: url)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.apiDateFormatter)
        return try decoder.decode(T.self, from: data)
    }
}
