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
        }
    }
}
