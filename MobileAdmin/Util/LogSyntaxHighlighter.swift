//
//  LogSyntaxHighlighter.swift
//  MobileAdmin
//
//  로그 한 줄 구문 강조 (`bat -l log` 느낌)
//  - 타임스탬프 / 로그 레벨 / [스레드 소스] / 문자열 / 숫자 / URL / IP / 예외 / 스택 트레이스
//  - 정규식 1개를 한 번만 훑는다 (왼쪽 우선, 구간이 겹치지 않음)
//  - 색은 LogTheme가 정한다
//

import SwiftUI

enum LogSyntaxHighlighter {

    // MARK: - 토큰

    enum TokenKind: CaseIterable {
        case stackFrame   // "    at com.foo.Bar.baz(Bar.java:10)"
        case timestamp
        case url
        case jsonKey      // "key":
        case string       // "..."
        case bracket      // [http-nio-58080-exec-27 Foo.java:248]
        case levelError
        case levelWarn
        case levelInfo
        case levelDebug
        case exception    // java.lang.NullPointerException
        case ip
        case number
        case constant     // null / true / false
        case key          // key=value 의 key
    }

    struct Token: Equatable {
        let kind: TokenKind
        let range: Range<String.Index>
    }

    /// 이보다 긴 줄은 앞부분만 강조한다 (한 줄짜리 대형 JSON 대비)
    static let maxHighlightLength = 4_000

    // 캡처 그룹 순서 = TokenKind.allCases 순서. 그룹 안쪽은 모두 비캡처(?:)로 유지할 것
    private static let regex: NSRegularExpression = {
        let levels = "ERROR|FATAL|SEVERE|CRITICAL|WARN|WARNING|INFO|NOTICE|DEBUG|TRACE"
        let parts: [String] = [
            #"^\s*at\s+[\w$.<>]+\(.*\)\s*$"#,
            #"(?<!\w)\d{4}[-/]\d{2}[-/]\d{2}(?:[T ]\d{2}:\d{2}:\d{2}(?:[.,]\d{1,6})?(?:Z|[+-]\d{2}:?\d{2})?)?|(?<![\w:])\d{2}:\d{2}:\d{2}(?:[.,]\d{1,6})?(?![\w:])"#,
            #"\bhttps?://[^\s"'<>\]\)]+"#,
            #""(?:[^"\\]|\\.)*"(?=\s*:)"#,
            #""(?:[^"\\]|\\.)*""#,
            #"\[(?!(?:\#(levels))\b)[A-Za-z][^\]\[{}"]{0,120}\]"#,
            #"\b(?:ERROR|FATAL|SEVERE|CRITICAL)\b"#,
            #"\b(?:WARN|WARNING)\b"#,
            #"\b(?:INFO|NOTICE)\b"#,
            #"\b(?:DEBUG|TRACE)\b"#,
            #"\b(?:[\w$]+\.)*[A-Z][\w$]*(?:Exception|Error)\b"#,
            #"(?<![\w.])\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?(?![\w.])"#,
            #"(?<![\w.$])\d+(?:\.\d+)?(?:ms|s|KB|MB|GB|%)?(?![\w.$]|\.\d)"#,
            #"(?<![\w$])(?:null|NULL|true|false)(?![\w$])"#,
            #"\b[A-Za-z_][\w.-]*(?==[^=])"#,
        ]
        let pattern = parts.map { "(\($0))" }.joined(separator: "|")
        // 패턴은 컴파일 타임 상수라 실패하지 않는다
        return try! NSRegularExpression(pattern: pattern)
    }()

    /// 한 줄을 토큰으로 나눈다 — 강조할 구간만 반환 (일반 텍스트는 제외)
    static func tokens(in text: String) -> [Token] {
        guard !text.isEmpty else { return [] }
        let ns = text as NSString
        let scan = NSRange(location: 0, length: min(ns.length, maxHighlightLength))
        let kinds = TokenKind.allCases
        var result: [Token] = []
        regex.enumerateMatches(in: text, range: scan) { match, _, _ in
            guard let match else { return }
            for (index, kind) in kinds.enumerated() {
                let nsRange = match.range(at: index + 1)
                guard nsRange.location != NSNotFound, let range = Range(nsRange, in: text) else { continue }
                result.append(Token(kind: kind, range: range))
                break
            }
        }
        return result
    }

    // MARK: - 스타일

    /// 구문 강조된 한 줄 — 색은 테마가 정한다 (plain 테마는 강조 없이 그대로)
    static func highlight(_ text: String, theme: LogTheme = .system) -> AttributedString {
        var attributed = AttributedString(text)
        guard theme.highlightsSyntax else { return attributed }
        for token in tokens(in: text) {
            guard let range = Range(token.range, in: attributed) else { continue }
            attributed[range].foregroundColor = theme.color(for: token.kind)
            switch token.kind {
            case .levelError, .levelWarn:
                attributed[range].inlinePresentationIntent = .stronglyEmphasized
            case .url:
                attributed[range].underlineStyle = .single
            default:
                break
            }
        }
        return attributed
    }
}
