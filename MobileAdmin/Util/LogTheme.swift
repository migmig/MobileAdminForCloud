//
//  LogTheme.swift
//  MobileAdmin
//
//  로그 뷰어 구문 강조 테마 — @AppStorage("logTheme")로 저장 (rawValue는 바꾸지 말 것)
//

import SwiftUI

enum LogTheme: String, CaseIterable, Identifiable {
    case system
    case plain
    case monokai
    case dracula
    case oneDark
    case nord
    case tokyoNight
    case gruvboxDark
    case githubDark
    case githubLight
    case solarizedDark
    case solarizedLight

    static let storageKey = "logTheme"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:         return "시스템"
        case .plain:          return "강조 없음"
        case .monokai:        return "Monokai"
        case .dracula:        return "Dracula"
        case .oneDark:        return "One Dark"
        case .nord:           return "Nord"
        case .tokyoNight:     return "Tokyo Night"
        case .gruvboxDark:    return "Gruvbox Dark"
        case .githubDark:     return "GitHub Dark"
        case .githubLight:    return "GitHub Light"
        case .solarizedDark:  return "Solarized Dark"
        case .solarizedLight: return "Solarized Light"
        }
    }

    /// 구문 강조를 하는 테마인지 (plain만 false)
    var highlightsSyntax: Bool { self != .plain }

    /// 고정 배경을 쓰는 테마의 팔레트 — system/plain은 nil (앱 라이트/다크를 따른다)
    var palette: LogPalette? {
        switch self {
        case .system, .plain: return nil
        case .monokai:        return .monokai
        case .dracula:        return .dracula
        case .oneDark:        return .oneDark
        case .nord:           return .nord
        case .tokyoNight:     return .tokyoNight
        case .gruvboxDark:    return .gruvboxDark
        case .githubDark:     return .githubDark
        case .githubLight:    return .githubLight
        case .solarizedDark:  return .solarizedDark
        case .solarizedLight: return .solarizedLight
        }
    }

    /// 토큰 색 — plain은 호출하지 않는다
    func color(for kind: LogSyntaxHighlighter.TokenKind) -> Color {
        guard let palette else { return Self.systemColor(for: kind) }
        switch kind {
        case .stackFrame:              return palette.red.opacity(0.8)
        case .timestamp:               return palette.cyan
        case .url, .jsonKey, .key:     return palette.blue
        case .string:                  return palette.yellow
        case .bracket, .levelDebug:    return palette.comment
        case .levelError, .exception:  return palette.red
        case .levelWarn:               return palette.orange
        case .levelInfo:               return palette.green
        case .ip, .number:             return palette.purple
        case .constant:                return palette.pink
        }
    }

    /// 시스템 색 — 라이트/다크 자동 대응
    private static func systemColor(for kind: LogSyntaxHighlighter.TokenKind) -> Color {
        switch kind {
        case .stackFrame: return .red.opacity(0.75)
        case .timestamp:  return .teal
        case .url:        return .blue
        case .jsonKey:    return .blue
        case .string:     return .brown
        case .bracket:    return .secondary
        case .levelError: return .red
        case .levelWarn:  return .orange
        case .levelInfo:  return .green
        case .levelDebug: return .secondary
        case .exception:  return .red
        case .ip:         return .indigo
        case .number:     return .purple
        case .constant:   return .pink
        case .key:        return .blue
        }
    }
}

// MARK: - 팔레트

struct LogPalette {
    let isDark: Bool
    let background: Color
    let foreground: Color
    let comment: Color
    let red: Color
    let orange: Color
    let yellow: Color
    let green: Color
    let cyan: Color
    let blue: Color
    let purple: Color
    let pink: Color

    init(isDark: Bool, bg: UInt32, fg: UInt32, comment: UInt32, red: UInt32, orange: UInt32, yellow: UInt32,
         green: UInt32, cyan: UInt32, blue: UInt32, purple: UInt32, pink: UInt32) {
        self.isDark = isDark
        background = Self.color(bg)
        foreground = Self.color(fg)
        self.comment = Self.color(comment)
        self.red = Self.color(red)
        self.orange = Self.color(orange)
        self.yellow = Self.color(yellow)
        self.green = Self.color(green)
        self.cyan = Self.color(cyan)
        self.blue = Self.color(blue)
        self.purple = Self.color(purple)
        self.pink = Self.color(pink)
    }

    private static func color(_ hex: UInt32) -> Color {
        Color(.sRGB,
              red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }

    static let monokai = LogPalette(isDark: true, bg: 0x272822, fg: 0xF8F8F2, comment: 0x8F908A,
                                    red: 0xF92672, orange: 0xFD971F, yellow: 0xE6DB74, green: 0xA6E22E,
                                    cyan: 0xA1EFE4, blue: 0x66D9EF, purple: 0xAE81FF, pink: 0xFD5FF0)
    static let dracula = LogPalette(isDark: true, bg: 0x282A36, fg: 0xF8F8F2, comment: 0x7C8BBE,
                                    red: 0xFF5555, orange: 0xFFB86C, yellow: 0xF1FA8C, green: 0x50FA7B,
                                    cyan: 0x8BE9FD, blue: 0x8BE9FD, purple: 0xBD93F9, pink: 0xFF79C6)
    static let oneDark = LogPalette(isDark: true, bg: 0x282C34, fg: 0xABB2BF, comment: 0x7F848E,
                                    red: 0xE06C75, orange: 0xD19A66, yellow: 0xE5C07B, green: 0x98C379,
                                    cyan: 0x56B6C2, blue: 0x61AFEF, purple: 0xC678DD, pink: 0xC678DD)
    static let nord = LogPalette(isDark: true, bg: 0x2E3440, fg: 0xD8DEE9, comment: 0x7B88A1,
                                 red: 0xBF616A, orange: 0xD08770, yellow: 0xEBCB8B, green: 0xA3BE8C,
                                 cyan: 0x8FBCBB, blue: 0x81A1C1, purple: 0xB48EAD, pink: 0xB48EAD)
    static let tokyoNight = LogPalette(isDark: true, bg: 0x1A1B26, fg: 0xA9B1D6, comment: 0x6B7394,
                                       red: 0xF7768E, orange: 0xFF9E64, yellow: 0xE0AF68, green: 0x9ECE6A,
                                       cyan: 0x7DCFFF, blue: 0x7AA2F7, purple: 0xBB9AF7, pink: 0xBB9AF7)
    static let gruvboxDark = LogPalette(isDark: true, bg: 0x282828, fg: 0xEBDBB2, comment: 0x928374,
                                        red: 0xFB4934, orange: 0xFE8019, yellow: 0xFABD2F, green: 0xB8BB26,
                                        cyan: 0x8EC07C, blue: 0x83A598, purple: 0xD3869B, pink: 0xD3869B)
    static let githubDark = LogPalette(isDark: true, bg: 0x0D1117, fg: 0xE6EDF3, comment: 0x8B949E,
                                       red: 0xFF7B72, orange: 0xFFA657, yellow: 0xD29922, green: 0x3FB950,
                                       cyan: 0x39C5CF, blue: 0x79C0FF, purple: 0xD2A8FF, pink: 0xF778BA)
    static let githubLight = LogPalette(isDark: false, bg: 0xFFFFFF, fg: 0x24292F, comment: 0x6E7781,
                                        red: 0xCF222E, orange: 0xBC4C00, yellow: 0x9A6700, green: 0x116329,
                                        cyan: 0x1B7C83, blue: 0x0550AE, purple: 0x8250DF, pink: 0xBF3989)
    static let solarizedDark = LogPalette(isDark: true, bg: 0x002B36, fg: 0x93A1A1, comment: 0x657B83,
                                          red: 0xDC322F, orange: 0xCB4B16, yellow: 0xB58900, green: 0x859900,
                                          cyan: 0x2AA198, blue: 0x268BD2, purple: 0x6C71C4, pink: 0xD33682)
    static let solarizedLight = LogPalette(isDark: false, bg: 0xFDF6E3, fg: 0x586E75, comment: 0x93A1A1,
                                           red: 0xDC322F, orange: 0xCB4B16, yellow: 0xB58900, green: 0x859900,
                                           cyan: 0x2AA198, blue: 0x268BD2, purple: 0x6C71C4, pink: 0xD33682)
}
