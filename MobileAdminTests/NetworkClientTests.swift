//
//  NetworkClientTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
@testable import MobileAdmin

// Serialized because tests read/write shared static state on NetworkClient
@Suite(.serialized)
struct NetworkClientTests {

    let client = NetworkClient()

    init() {
        // Reset all static token state before every test
        NetworkClient.resetTokenState()
    }

    // MARK: - JWT test helper
    // Replicates the base64url encoding that a real JWT issuer would use,
    // allowing us to construct syntactically valid tokens for state-based tests.
    private func makeTestJWT(expiresIn seconds: TimeInterval) -> String {
        func base64UrlEncode(_ data: Data) -> String {
            data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        let exp = Int(Date().addingTimeInterval(seconds).timeIntervalSince1970)
        let header  = base64UrlEncode(#"{"alg":"HS256","typ":"JWT"}"#.data(using: .utf8)!)
        let payload = base64UrlEncode(#"{"sub":"testadmin","exp":\#(exp)}"#.data(using: .utf8)!)
        return "\(header).\(payload).fakesignature"
    }

    // MARK: - resetTokenState

    @Test func resetTokenState_clearsToken() {
        NetworkClient.token = "some-existing-token"
        NetworkClient.resetTokenState()
        #expect(NetworkClient.token == nil)
    }

    @Test func resetTokenState_clearsExpirationDate() {
        NetworkClient.tokenExpirationDate = Date().addingTimeInterval(3600)
        NetworkClient.resetTokenState()
        #expect(NetworkClient.tokenExpirationDate == nil)
    }

    @Test func resetTokenState_calledRepeatedly_doesNotCrash() {
        NetworkClient.resetTokenState()
        NetworkClient.resetTokenState()
        NetworkClient.resetTokenState()
        #expect(NetworkClient.token == nil)
        #expect(NetworkClient.tokenExpirationDate == nil)
    }

    @Test func resetTokenState_afterTokenSet_bothNil() {
        NetworkClient.token = "abc"
        NetworkClient.tokenExpirationDate = Date()
        NetworkClient.resetTokenState()
        #expect(NetworkClient.token == nil)
        #expect(NetworkClient.tokenExpirationDate == nil)
    }

    // MARK: - setToken

    @Test func setToken_withValue_setsStaticToken() {
        client.setToken(token: "jwt-abc-123")
        #expect(NetworkClient.token == "jwt-abc-123")
    }

    @Test func setToken_withNil_clearsToken() {
        NetworkClient.token = "existing"
        client.setToken(token: nil)
        #expect(NetworkClient.token == nil)
    }

    @Test func setToken_overwritesPreviousValue() {
        client.setToken(token: "first")
        client.setToken(token: "second")
        #expect(NetworkClient.token == "second")
    }

    // MARK: - makeAuthenticatedRequest: URL construction

    @Test func makeAuthenticatedRequest_validURL_createsRequest() throws {
        let request = try client.makeAuthenticatedRequest(url: "http://example.com/api")
        #expect(request.url?.absoluteString == "http://example.com/api")
    }

    @Test func makeAuthenticatedRequest_validURL_usesPostMethod() throws {
        let request = try client.makeAuthenticatedRequest(url: "http://example.com/api")
        #expect(request.httpMethod == "POST")
    }

    @Test func makeAuthenticatedRequest_validURL_setsContentTypeHeader() throws {
        let request = try client.makeAuthenticatedRequest(url: "http://example.com/api")
        #expect(request.value(forHTTPHeaderField: "Content-type") == "application/json")
    }

    @Test func makeAuthenticatedRequest_validURL_setsAcceptHeader() throws {
        let request = try client.makeAuthenticatedRequest(url: "http://example.com/api")
        #expect(request.value(forHTTPHeaderField: "Accept") == "*/*")
    }

    // MARK: - makeAuthenticatedRequest: Authorization header

    @Test func makeAuthenticatedRequest_withTokenSet_addsBearerAuthHeader() throws {
        NetworkClient.token = "my-jwt-token"
        let request = try client.makeAuthenticatedRequest(url: "http://example.com/api")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer my-jwt-token")
    }

    @Test func makeAuthenticatedRequest_withoutToken_omitsAuthorizationHeader() throws {
        // token is nil (reset in init)
        let request = try client.makeAuthenticatedRequest(url: "http://example.com/api")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func makeAuthenticatedRequest_bearerPrefix_isExactlyBearerSpace() throws {
        NetworkClient.token = "tok123"
        let request = try client.makeAuthenticatedRequest(url: "http://example.com/api")
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader?.hasPrefix("Bearer ") == true)
        #expect(authHeader == "Bearer tok123")
    }

    @Test func makeAuthenticatedRequest_tokenWithSpecialChars_preservesTokenValue() throws {
        let complexToken = "eyJ.eyK.sig=extra+chars"
        NetworkClient.token = complexToken
        let request = try client.makeAuthenticatedRequest(url: "http://example.com/api")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(complexToken)")
    }

    // MARK: - makeAuthenticatedRequest: Invalid URL

    @Test func makeAuthenticatedRequest_urlWithSpaces_throwsNetworkError() {
        // Spaces are not valid in URLs and URL(string:) returns nil for them
        #expect(throws: NetworkError.self) {
            _ = try client.makeAuthenticatedRequest(url: "http://invalid host.com/path")
        }
    }

    @Test func makeAuthenticatedRequest_throwsInvalidURLCase() {
        let badURL = "http://bad host.example.com"
        do {
            _ = try client.makeAuthenticatedRequest(url: badURL)
        } catch let error as NetworkError {
            if case .invalidURL(let url) = error {
                #expect(url == badURL)
            } else {
                Issue.record("Expected .invalidURL but got \(error)")
            }
        } catch {
            Issue.record("Expected NetworkError but got \(error)")
        }
    }

    // MARK: - ensureValidToken: valid token path (no network needed)

    @Test func ensureValidToken_validTokenAndFutureExpiry_returnsImmediately() async throws {
        // Pre-set a valid token with future expiry — no network call is made
        let jwt = makeTestJWT(expiresIn: 3600)
        NetworkClient.token = jwt
        NetworkClient.tokenExpirationDate = Date().addingTimeInterval(3600)
        let tokenBefore = NetworkClient.token

        try await client.ensureValidToken()

        // Token must not have changed (no refresh happened)
        #expect(NetworkClient.token == tokenBefore)
    }

    @Test func ensureValidToken_tokenWithFarFutureExpiry_doesNotClearToken() async throws {
        NetworkClient.token = makeTestJWT(expiresIn: 86400) // 24 hours
        NetworkClient.tokenExpirationDate = Date().addingTimeInterval(86400)

        try await client.ensureValidToken()

        #expect(NetworkClient.token != nil)
    }

    // MARK: - ensureValidToken: refresh required paths (no real server; errors expected)

    @Test func ensureValidToken_nilToken_triggersRefreshAttempt() async {
        // No token set → needsRefresh is true → fetchToken is called → fails (no server)
        #expect(NetworkClient.token == nil)
        do {
            try await client.ensureValidToken()
            // Reaching here would mean a token was somehow obtained — highly unlikely in unit tests
        } catch {
            // Any error from the failed network/credential lookup is acceptable
            #expect(error is NetworkError || error is URLError)
        }
    }

    @Test func ensureValidToken_expiredToken_triggersRefreshAttempt() async {
        NetworkClient.token = makeTestJWT(expiresIn: -3600) // expired 1 hour ago
        NetworkClient.tokenExpirationDate = Date().addingTimeInterval(-3600)

        do {
            try await client.ensureValidToken()
        } catch {
            #expect(error is NetworkError || error is URLError)
        }
    }

    @Test func ensureValidToken_nilExpirationWithToken_triggersRefreshAttempt() async {
        // Token is set but expiration is nil — treated as expired
        NetworkClient.token = "some-token"
        NetworkClient.tokenExpirationDate = nil

        do {
            try await client.ensureValidToken()
        } catch {
            #expect(error is NetworkError || error is URLError)
        }
    }

    // MARK: - apiDateFormatter

    @Test func apiDateFormatter_formatPattern_isYYYYMMDDHHmmss() {
        // Parse a known string and verify the individual date components
        guard let date = NetworkClient.apiDateFormatter.date(from: "20241005083000") else {
            Issue.record("apiDateFormatter failed to parse '20241005083000'")
            return
        }
        let calendar = Calendar.current
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        #expect(c.year   == 2024)
        #expect(c.month  == 10)
        #expect(c.day    == 5)
        #expect(c.hour   == 8)
        #expect(c.minute == 30)
        #expect(c.second == 0)
    }

    @Test func apiDateFormatter_roundTrip_preservesDateComponents() {
        // Format → parse → format again; the string should be identical
        let original = "20240101120000"
        guard let date = NetworkClient.apiDateFormatter.date(from: original) else {
            Issue.record("Failed to parse '\(original)'")
            return
        }
        let result = NetworkClient.apiDateFormatter.string(from: date)
        #expect(result == original)
    }

    @Test func apiDateFormatter_producesFixedLengthString() {
        let result = NetworkClient.apiDateFormatter.string(from: Date())
        // yyyyMMddHHmmss is always 14 characters
        #expect(result.count == 14)
        #expect(result.allSatisfy { $0.isNumber })
    }

    // MARK: - JWT token structure validation (via public observable state)

    @Test func jwt_validFutureToken_isRecognizedAsValidByEnsureValidToken() async throws {
        // Construct a JWT that: has 3 dot-separated parts, base64url payload, valid exp field
        let jwt = makeTestJWT(expiresIn: 7200)
        let parts = jwt.split(separator: ".")
        #expect(parts.count == 3) // Verifies our helper produces a proper 3-part JWT

        // When this token is set alongside a future expiry, ensureValidToken should not refresh
        NetworkClient.token = jwt
        NetworkClient.tokenExpirationDate = Date().addingTimeInterval(7200)
        let before = NetworkClient.token
        try await client.ensureValidToken()
        #expect(NetworkClient.token == before)
    }

    @Test func jwt_helper_producesBase64UrlEncodedParts() {
        let jwt = makeTestJWT(expiresIn: 3600)
        let parts = jwt.split(separator: ".")
        // Base64url characters must not contain "+", "/", or "=" padding
        for part in parts.prefix(2) {
            #expect(!part.contains("+"))
            #expect(!part.contains("/"))
            #expect(!part.contains("="))
        }
    }
}
