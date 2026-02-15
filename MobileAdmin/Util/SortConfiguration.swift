//
//  SortConfiguration.swift
//  MobileAdmin
//
//  정렬 필드, 방향, 필터 설정을 관리하는 구조체
//

import SwiftUI

// MARK: - Sort Field
enum SortField: String, CaseIterable {
    case date
    case code
    case frequency
    case userId

    var displayName: String {
        switch self {
        case .date:
            return "날짜"
        case .code:
            return "코드"
        case .frequency:
            return "발생 빈도"
        case .userId:
            return "사용자"
        }
    }

    var systemImage: String {
        switch self {
        case .date:
            return "calendar"
        case .code:
            return "curly.braces"
        case .frequency:
            return "repeat"
        case .userId:
            return "person"
        }
    }

    /// ErrorCloudItem을 정렬 기준에 따라 비교
    func compare(_ a: ErrorCloudItem, _ b: ErrorCloudItem) -> Bool {
        switch self {
        case .date:
            let aDate = Date(from: a.registerDt ?? "") ?? .distantPast
            let bDate = Date(from: b.registerDt ?? "") ?? .distantPast
            return aDate > bDate // 최신순이 기본

        case .code:
            return (a.code ?? "") < (b.code ?? "")

        case .frequency:
            let aCount = a.occurrenceCount ?? 1
            let bCount = b.occurrenceCount ?? 1
            return aCount > bCount // 많은 순서가 기본

        case .userId:
            return (a.userId ?? "") < (b.userId ?? "")
        }
    }
}

// MARK: - Sort Direction
enum SortDirection: String, CaseIterable {
    case ascending
    case descending

    var displayName: String {
        switch self {
        case .ascending:
            return "오름차순"
        case .descending:
            return "내림차순"
        }
    }

    var systemImage: String {
        switch self {
        case .ascending:
            return "arrow.up"
        case .descending:
            return "arrow.down"
        }
    }

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

// MARK: - Sort Configuration
struct SortConfiguration: Equatable {
    var field: SortField = .date
    var direction: SortDirection = .descending
    var secondaryField: SortField = .code
    var activeFilters: [String] = []

    static let `default` = SortConfiguration()

    /// 정렬된 오류 목록 반환
    func sort(_ items: [ErrorCloudItem]) -> [ErrorCloudItem] {
        var sorted = items.sorted { a, b in
            let primaryComparison = field.compare(a, b)

            // 같으면 보조 필드로 비교
            if primaryValueEqual(a, b, by: field) {
                return secondaryField.compare(a, b)
            }

            return primaryComparison
        }

        // 정렬 방향 반전 (descending인 경우)
        if direction == .descending {
            // 기본 compare 함수가 이미 내림차순이므로,
            // ascending일 때만 반전하면 됨
            if direction == .ascending {
                sorted.reverse()
            }
        }

        return sorted
    }

    /// 두 아이템의 주 정렬 필드 값이 같은지 확인
    private func primaryValueEqual(_ a: ErrorCloudItem, _ b: ErrorCloudItem, by field: SortField) -> Bool {
        switch field {
        case .date:
            let aDate = Date(from: a.registerDt ?? "") ?? .distantPast
            let bDate = Date(from: b.registerDt ?? "") ?? .distantPast
            return aDate == bDate

        case .code:
            return (a.code ?? "") == (b.code ?? "")

        case .frequency:
            return (a.occurrenceCount ?? 1) == (b.occurrenceCount ?? 1)

        case .userId:
            return (a.userId ?? "") == (b.userId ?? "")
        }
    }

    /// 현재 정렬 상태를 문자열로 반환 (UI 표시용)
    var displayText: String {
        "\(field.displayName) (\(direction.displayName))"
    }

    /// 정렬 방향 토글
    mutating func toggleDirection() {
        direction.toggle()
    }

    /// 정렬 필드 변경
    mutating func setField(_ newField: SortField) {
        field = newField
        // 필드 변경 시 방향 초기화
        direction = newField == .frequency ? .descending : .ascending
    }
}
