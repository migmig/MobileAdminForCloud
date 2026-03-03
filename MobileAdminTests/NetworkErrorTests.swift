//
//  NetworkErrorTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
@testable import MobileAdmin

struct NetworkErrorTests {

    // MARK: - errorDescription: non-nil for all cases

    @Test func invalidURL_errorDescription_isNonNil() {
        let error = NetworkError.invalidURL("http://example.com")
        #expect(error.errorDescription != nil)
    }

    @Test func missingCredential_errorDescription_isNonNil() {
        let error = NetworkError.missingCredential
        #expect(error.errorDescription != nil)
    }

    @Test func missingToken_errorDescription_isNonNil() {
        let error = NetworkError.missingToken
        #expect(error.errorDescription != nil)
    }

    @Test func tokenExpired_errorDescription_isNonNil() {
        let error = NetworkError.tokenExpired
        #expect(error.errorDescription != nil)
    }

    @Test func httpError_errorDescription_isNonNil() {
        let error = NetworkError.httpError(statusCode: 500, url: "/api/data")
        #expect(error.errorDescription != nil)
    }

    @Test func decodingError_errorDescription_isNonNil() {
        let underlying = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "test"))
        let error = NetworkError.decodingError(underlying: underlying, url: "/api/data")
        #expect(error.errorDescription != nil)
    }

    @Test func noData_errorDescription_isNonNil() {
        let error = NetworkError.noData
        #expect(error.errorDescription != nil)
    }

    // MARK: - errorDescription: content correctness

    @Test func invalidURL_errorDescription_containsTheURL() {
        let badURL = "http://this-is-the-bad-url.example.com"
        let error = NetworkError.invalidURL(badURL)
        #expect(error.errorDescription?.contains(badURL) == true)
    }

    @Test func httpError_errorDescription_containsStatusCode() {
        let error = NetworkError.httpError(statusCode: 404, url: "/api/resource")
        #expect(error.errorDescription?.contains("404") == true)
    }

    @Test func httpError_errorDescription_containsURL() {
        let url = "/api/specific-endpoint"
        let error = NetworkError.httpError(statusCode: 403, url: url)
        #expect(error.errorDescription?.contains(url) == true)
    }

    @Test func decodingError_errorDescription_containsURL() {
        let url = "/api/decode-this"
        let underlying = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
        let error = NetworkError.decodingError(underlying: underlying, url: url)
        #expect(error.errorDescription?.contains(url) == true)
    }

    @Test func httpError_500_errorDescription_contains500() {
        let error = NetworkError.httpError(statusCode: 500, url: "/crash")
        #expect(error.errorDescription?.contains("500") == true)
    }

    @Test func httpError_401_errorDescription_contains401() {
        let error = NetworkError.httpError(statusCode: 401, url: "/auth")
        #expect(error.errorDescription?.contains("401") == true)
    }

    // MARK: - errorDescription: non-empty strings

    @Test func allCases_errorDescription_areNonEmpty() {
        let underlying = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "e"))
        let errors: [NetworkError] = [
            .invalidURL("http://x.com"),
            .missingCredential,
            .missingToken,
            .tokenExpired,
            .httpError(statusCode: 500, url: "/api"),
            .decodingError(underlying: underlying, url: "/api"),
            .noData
        ]
        for error in errors {
            #expect(error.errorDescription?.isEmpty == false, "errorDescription should not be empty for \(error)")
        }
    }

    // MARK: - Associated value extraction

    @Test func invalidURL_associatedValue_roundTrips() {
        let url = "http://roundtrip.example.com/path"
        let error = NetworkError.invalidURL(url)
        if case .invalidURL(let extractedURL) = error {
            #expect(extractedURL == url)
        } else {
            Issue.record("Expected .invalidURL case")
        }
    }

    @Test func httpError_associatedValues_roundTrip() {
        let statusCode = 503
        let url = "/api/unavailable"
        let error = NetworkError.httpError(statusCode: statusCode, url: url)
        if case .httpError(let code, let extractedURL) = error {
            #expect(code == statusCode)
            #expect(extractedURL == url)
        } else {
            Issue.record("Expected .httpError case")
        }
    }

    @Test func decodingError_associatedValues_roundTrip() {
        let url = "/api/decode"
        struct FakeError: Error {}
        let underlying = FakeError()
        let error = NetworkError.decodingError(underlying: underlying, url: url)
        if case .decodingError(_, let extractedURL) = error {
            #expect(extractedURL == url)
        } else {
            Issue.record("Expected .decodingError case")
        }
    }

    // MARK: - LocalizedError conformance

    @Test func networkError_conformsToLocalizedError() {
        let error: any Error = NetworkError.missingToken
        #expect(error is LocalizedError)
    }

    @Test func networkError_localizedDescription_isNotEmpty() {
        // LocalizedError.localizedDescription falls back to errorDescription
        let error = NetworkError.missingCredential
        #expect(error.localizedDescription.isEmpty == false)
    }

    // MARK: - Distinct descriptions for different cases

    @Test func httpError_differentStatusCodes_produceDifferentDescriptions() {
        let e404 = NetworkError.httpError(statusCode: 404, url: "/api")
        let e500 = NetworkError.httpError(statusCode: 500, url: "/api")
        #expect(e404.errorDescription != e500.errorDescription)
    }

    @Test func invalidURL_differentURLs_produceDifferentDescriptions() {
        let e1 = NetworkError.invalidURL("http://url-one.com")
        let e2 = NetworkError.invalidURL("http://url-two.com")
        #expect(e1.errorDescription != e2.errorDescription)
    }
}
