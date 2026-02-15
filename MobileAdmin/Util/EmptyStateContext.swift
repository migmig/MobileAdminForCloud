//
//  EmptyStateContext.swift
//  MobileAdmin
//
//  빈 상태 컨텍스트 - 상황별 empty state 메시지 정의
//

import SwiftUI

enum EmptyStateContext {
    case loading
    case noResults
    case noData
    case filterEmpty

    var systemImage: String {
        switch self {
        case .loading:
            return "hourglass"
        case .noResults:
            return "magnifyingglass.circle"
        case .noData:
            return "checkmark.shield"
        case .filterEmpty:
            return "slider.horizontal.3"
        }
    }

    var title: String {
        switch self {
        case .loading:
            return "조회 중입니다"
        case .noResults:
            return "검색 결과가 없습니다"
        case .noData:
            return "오류가 없습니다"
        case .filterEmpty:
            return "조건을 만족하는 항목이 없습니다"
        }
    }

    var description: String? {
        switch self {
        case .loading:
            return "잠깐만 기다려주세요"
        case .noResults:
            return "다른 키워드로 검색해 보세요"
        case .noData:
            return "조회 기간을 변경해 보세요"
        case .filterEmpty:
            return "필터 조건을 변경해 보세요"
        }
    }

    var iconColor: Color {
        switch self {
        case .loading:
            return .blue
        case .noResults:
            return .orange
        case .noData:
            return .green
        case .filterEmpty:
            return .purple
        }
    }
}
