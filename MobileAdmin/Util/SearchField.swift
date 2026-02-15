//
//  SearchField.swift
//  MobileAdmin
//
//  오류 검색 필드 정의 - description, code, userId, restUrl 등 검색 가능한 필드들
//

import SwiftUI

enum SearchField: String, CaseIterable {
    case description
    case code
    case userId
    case restUrl

    var displayName: String {
        switch self {
        case .description:
            return "설명"
        case .code:
            return "코드"
        case .userId:
            return "사용자ID"
        case .restUrl:
            return "URL"
        }
    }

    var systemImage: String {
        switch self {
        case .description:
            return "text.alignleft"
        case .code:
            return "curly braces"
        case .userId:
            return "person"
        case .restUrl:
            return "link"
        }
    }

    /// 주어진 ErrorCloudItem에서 검색 쿼리와 일치하는지 확인
    func matches(item: ErrorCloudItem, query: String) -> Bool {
        guard !query.isEmpty else { return true }

        let q = query.lowercased()
        switch self {
        case .description:
            return item.description?.localizedCaseInsensitiveContains(query) == true
        case .code:
            return item.code?.localizedCaseInsensitiveContains(query) == true
        case .userId:
            return item.userId?.localizedCaseInsensitiveContains(query) == true
        case .restUrl:
            return item.restUrl?.localizedCaseInsensitiveContains(query) == true
        }
    }
}
