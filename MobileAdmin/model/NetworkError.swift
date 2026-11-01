//
//  NetworkError.swift
//  MobileAdmin
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL(String)
    case missingCredential
    case missingToken
    case tokenExpired
    case httpError(statusCode: Int, url: String)
    case decodingError(underlying: Error, url: String)
    case noData
    /// 서버가 실패 응답과 함께 오류 바디({"error"} 또는 {"message"})를 준 경우
    case server(statusCode: Int, message: String?, url: String)
    /// 200이지만 HTML(SPA 폴백) 응답 — 현재 서버가 해당 API를 지원하지 않음
    case unsupportedEndpoint(url: String)
    /// 응답 Content-Type이 기대와 다름
    case unexpectedContentType(String?, url: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "잘못된 URL: \(url)"
        case .missingCredential:
            return "인증 정보가 없습니다"
        case .missingToken:
            return "인증 토큰이 없습니다"
        case .tokenExpired:
            return "인증 토큰이 만료되었습니다"
        case .httpError(let code, let url):
            return "HTTP 오류 \(code): \(url)"
        case .decodingError(let error, let url):
            return "데이터 파싱 오류 (\(url)): \(error.localizedDescription)"
        case .noData:
            return "응답 데이터가 없습니다"
        case .server(let code, let message, _):
            return message ?? "HTTP 오류 \(code)"
        case .unsupportedEndpoint:
            return "현재 서버에서 지원하지 않는 기능입니다"
        case .unexpectedContentType(let type, let url):
            return "예상하지 못한 응답 형식(\(type ?? "없음")): \(url)"
        }
    }
}
