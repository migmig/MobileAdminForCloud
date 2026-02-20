import SwiftUI

// MARK: - 사용여부 상태 헬퍼 (iOS/macOS 공용)
struct UseAtStatus {
    let label: String
    let code: String
    let icon: String

    static let filters: [UseAtStatus] = [
        UseAtStatus(label: "전체",   code: "all", icon: "line.3.horizontal.decrease.circle"),
        UseAtStatus(label: "사용",   code: "Y",   icon: "checkmark.circle.fill"),
        UseAtStatus(label: "미사용", code: "N",   icon: "xmark.circle.fill"),
    ]

    static func icon(for useAt: String?) -> String {
        useAt == "Y" ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    static func label(for useAt: String?) -> String {
        useAt == "Y" ? "사용" : "미사용"
    }

    static func color(for useAt: String?) -> Color {
        useAt == "Y" ? AppColor.success : AppColor.inactive
    }
}
