//
//  AppDesign.swift
//  MobileAdmin
//
//  디자인 시스템 - 색상, 폰트, 간격 중앙 관리
//

import SwiftUI

// MARK: - 색상 시스템
enum AppColor {
    // 상태 색상
    static let success = Color.blue
    static let error = Color.red
    static let warning = Color.yellow
    static let running = Color.purple
    static let canceled = Color.pink
    static let inactive = Color.gray

    // 환경 색상
    static let envLocal = Color.green
    static let envDev = Color.blue
    static let envProd = Color.purple

    // UI 요소 색상
    static let selected = Color.blue
    static let deselected = Color.gray
    static let destructive = Color.red
    static let link = Color.blue
    static let icon = Color.accentColor
    static let userIcon = Color.orange

    // 토스트 그라디언트
    static let toastGradient = LinearGradient(
        gradient: Gradient(colors: [Color.purple, Color.blue]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - 빌드 상태 색상
    static func buildStatus(_ status: String) -> Color {
        switch status {
        case "success":  return success
        case "fail":     return error
        case "upload":   return running
        case "canceled": return canceled
        default:         return inactive
        }
    }

    // MARK: - 파이프라인 상태 색상
    static func pipelineStatus(_ status: String) -> Color {
        switch status {
        case "success":  return success
        case "running":  return warning
        default:         return error
        }
    }

    // MARK: - 배포 상태 색상
    static func deployStatus(_ status: String) -> Color {
        switch status {
        case "success":    return success
        case "inprogress": return running
        default:           return error
        }
    }

    // MARK: - 개시/마감 상태 색상
    static func closeDeptStatus(_ closeGb: String?) -> Color {
        switch closeGb {
        case "1": return .purple
        case "2": return error
        case "3": return .green
        default:  return success
        }
    }

    // MARK: - 환경 타입 색상
    static func envType(_ type: String) -> Color {
        switch type {
        case "local": return envLocal
        case "dev":   return envDev
        case "prod":  return envProd
        default:      return .secondary
        }
    }
}

// MARK: - 폰트 시스템
enum AppFont {
    static let sectionTitle = Font.title3
    static let listTitle = Font.headline
    static let listSubtitle = Font.subheadline
    static let body = Font.body
    static let caption = Font.caption
    static let captionSmall = Font.caption2
    static let sidebarItem = Font.title2
    static let timestamp = Font.system(size: 11)
    static let mono = Font.caption.monospaced()
    static let monoDigit = Font.caption.monospacedDigit()
}

// MARK: - 간격 시스템
enum AppSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 40
}

// MARK: - 코너 반경
enum AppRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
}

// MARK: - 그림자
enum AppShadow {
    static func card() -> some View {
        Color.black.opacity(0.06)
    }
    static let cardRadius: CGFloat = 4
    static let cardY: CGFloat = 2
}

// MARK: - 공통 뷰 수정자
extension View {
    func sectionHeaderStyle() -> some View {
        self
            .font(AppFont.caption)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}
