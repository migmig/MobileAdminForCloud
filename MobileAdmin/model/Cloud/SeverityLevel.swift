//
//  SeverityLevel.swift
//  MobileAdmin
//
//  오류 심각도 레벨 정의 (critical, high, medium, low)
//

import SwiftUI

enum SeverityLevel: String, CaseIterable, Codable {
    case critical
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .critical:
            return "긴급"
        case .high:
            return "높음"
        case .medium:
            return "중간"
        case .low:
            return "낮음"
        }
    }

    var color: Color {
        switch self {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }

    var systemImage: String {
        switch self {
        case .critical:
            return "exclamationmark.circle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .medium:
            return "exclamationmark.square.fill"
        case .low:
            return "info.circle.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .critical:
            return 0
        case .high:
            return 1
        case .medium:
            return 2
        case .low:
            return 3
        }
    }

    /// 서버에서 반환한 문자열 값으로부터 SeverityLevel 파싱
    static func from(_ value: String?) -> SeverityLevel {
        guard let value = value?.lowercased() else { return .medium }

        switch value {
        case "critical", "c":
            return .critical
        case "high", "h":
            return .high
        case "medium", "m", "normal":
            return .medium
        case "low", "l":
            return .low
        default:
            return .medium
        }
    }

    /// 오류 코드/메시지 패턴으로부터 심각도 추론 (서버에서 제공하지 않을 경우용)
    static func derived(from errorCloudItem: ErrorCloudItem) -> SeverityLevel {
        let code = errorCloudItem.code?.lowercased() ?? ""
        let message = errorCloudItem.msg?.lowercased() ?? ""
        let description = errorCloudItem.description?.lowercased() ?? ""

        // 긴급 키워드
        if code.contains("500") || code.contains("fatal") ||
           message.contains("fatal") || message.contains("panic") ||
           description.contains("critical") {
            return .critical
        }

        // 높음 키워드
        if code.contains("400") || code.contains("error") ||
           message.contains("error") || message.contains("exception") ||
           description.contains("fail") {
            return .high
        }

        // 낮음 키워드
        if code.contains("200") || code.contains("info") ||
           message.contains("info") || message.contains("warn") {
            return .low
        }

        // 기본값
        return .medium
    }
}
