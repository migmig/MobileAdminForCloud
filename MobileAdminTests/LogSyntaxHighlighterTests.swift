//
//  LogSyntaxHighlighterTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
@testable import MobileAdmin

struct LogSyntaxHighlighterTests {

    private func tokens(_ text: String) -> [(LogSyntaxHighlighter.TokenKind, String)] {
        LogSyntaxHighlighter.tokens(in: text).map { ($0.kind, String(text[$0.range])) }
    }

    @Test func logbackLine() {
        let line = #"2025/06/18 14:02:09.619 [http-nio-58080-exec-27 Foo.java:249] INFO c.g.Foo - 요청 JSON : [{"goodsId":1,"name":"a b","ok":true}]"#
        let result = tokens(line)
        #expect(result.map(\.0) == [.timestamp, .bracket, .levelInfo, .jsonKey, .number, .jsonKey, .string, .jsonKey, .constant])
        #expect(result[0].1 == "2025/06/18 14:02:09.619")
        #expect(result[1].1 == "[http-nio-58080-exec-27 Foo.java:249]")
    }

    @Test func bracketedLevelAndException() {
        let result = tokens("2025-06-18T14:02:13.833+09:00 [ERROR] java.lang.NullPointerException: userId=abc from 10.0.0.12:8080 https://a.b/c?d=1")
        #expect(result.map(\.0) == [.timestamp, .levelError, .exception, .key, .ip, .url])
    }

    @Test func identifiersAreNotNumbers() {
        // 인터페이스 ID / 사용자 ID 안의 숫자는 강조하지 않는다
        #expect(tokens("sEsbId : IF_UTC_MDS_172 UT00000013213").isEmpty)
        #expect(tokens("response [200, 97ms]").map(\.1) == ["200", "97ms"])
        // 자바 람다 이름 속 null/숫자도 강조하지 않는다
        #expect(tokens("lambda$null$3 - done").isEmpty)
    }

    @Test func stackFrameIsWholeLine() {
        let line = "    at com.foo.Bar.baz(Bar.java:10)"
        #expect(tokens(line).map(\.0) == [.stackFrame])
    }

    @Test func longLineOnlyHighlightsHead() {
        let line = String(repeating: "x ", count: LogSyntaxHighlighter.maxHighlightLength) + "ERROR"
        #expect(tokens(line).isEmpty)
    }

    @Test func plainThemeAddsNoColor() {
        let line = "2025/06/18 14:02:09.619 ERROR boom"
        #expect(LogSyntaxHighlighter.highlight(line, theme: .plain) == AttributedString(line))
        #expect(LogSyntaxHighlighter.highlight(line, theme: .monokai) != AttributedString(line))
    }

    @Test func everyThemeHasTitleAndStableRawValue() {
        #expect(Set(LogTheme.allCases.map(\.title)).count == LogTheme.allCases.count)
        #expect(LogTheme(rawValue: "system") == .system)
        #expect(LogTheme.system.palette == nil && LogTheme.plain.palette == nil)
        #expect(LogTheme.allCases.filter { $0.palette != nil }.count == 10)
    }
}
