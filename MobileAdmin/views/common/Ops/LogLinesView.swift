//
//  LogLinesView.swift
//  MobileAdmin
//
//  공용 로그 텍스트 뷰어 — 서버 로그 내용 / 사용자 로그 실시간 tail 공용
//  - LazyVStack으로 1만 줄 이상도 스크롤 성능 유지
//  - 줄마다 구문 강조(LogSyntaxHighlighter) + 검색어 하이라이트
//  - follow: 새 줄이 오면 맨 아래로 이동, 사용자가 위로 스크롤하면 자동 해제
//

import SwiftUI

struct LogLinesView: View {
    let lines: [LogLine]
    var searchQuery: String = ""
    var currentMatchID: LogLine.ID? = nil
    var wrap: Bool = true
    var theme: LogTheme = .system
    @Binding var follow: Bool

    @Environment(\.colorScheme) private var systemColorScheme

    /// 화면 하단에 걸친 줄 id — 사용자 스크롤 감지용
    @State private var bottomVisibleID: LogLine.ID?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(wrap ? .vertical : [.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { line in
                        LogLineRow(line: line,
                                   query: searchQuery,
                                   isCurrentMatch: line.id == currentMatchID,
                                   wrap: wrap,
                                   theme: theme)
                            .id(line.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .textSelection(.enabled)
                .foregroundStyle(theme.palette?.foreground ?? Color.primary)
            }
            .scrollPosition(id: $bottomVisibleID, anchor: .bottom)
            // 최근 줄(맨 아래)부터 보여준다 — 줄바꿈 해제 시 가로는 왼쪽 정렬
            .defaultScrollAnchor(.bottomLeading)
            .onChange(of: lines.last?.id) { _, newLast in
                guard follow, let newLast else { return }
                proxy.scrollTo(newLast, anchor: .bottom)
            }
            .onChange(of: follow) { _, isOn in
                guard isOn, let last = lines.last?.id else { return }
                proxy.scrollTo(last, anchor: .bottom)
            }
            .onChange(of: currentMatchID) { _, id in
                guard let id else { return }
                follow = false
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
            .onChange(of: bottomVisibleID) { _, visible in
                // 사용자가 위로 스크롤하면 따라가기 해제, 맨 아래로 돌아오면 다시 켬
                guard let visible, let last = lines.last?.id else { return }
                if visible < last - 1 {
                    if follow { follow = false }
                } else if visible == last, !follow, currentMatchID == nil {
                    follow = true
                }
            }
        }
        .background(theme.palette?.background ?? Color.secondary.opacity(0.04))
        // 고정 배경 테마는 스크롤바/선택 색도 배경 밝기에 맞춘다
        .environment(\.colorScheme, theme.palette.map { $0.isDark ? .dark : .light } ?? systemColorScheme)
    }
}

// MARK: - 한 줄

private struct LogLineRow: View, Equatable {
    let line: LogLine
    let query: String
    let isCurrentMatch: Bool
    let wrap: Bool
    let theme: LogTheme

    var body: some View {
        content
            .font(AppFont.mono)
            .lineLimit(wrap ? nil : 1)
            .fixedSize(horizontal: !wrap, vertical: false)
            .frame(maxWidth: wrap ? .infinity : nil, alignment: .leading)
            .padding(.vertical, 1)
            .background(isCurrentMatch ? Color.orange.opacity(0.25) : Color.clear)
    }

    private var content: Text {
        // 빈 줄도 높이를 유지
        guard !line.text.isEmpty else { return Text(" ") }
        return Text(Self.highlighted(line.text, query: query, theme: theme))
    }

    /// 구문 강조 + 검색어 일치 구간 하이라이트 (대소문자 무시)
    static func highlighted(_ text: String, query: String, theme: LogTheme = .system) -> AttributedString {
        var attributed = LogSyntaxHighlighter.highlight(text, theme: theme)
        guard !query.isEmpty else { return attributed }
        var searchRange = text.startIndex..<text.endIndex
        while let found = text.range(of: query, options: .caseInsensitive, range: searchRange) {
            if let range = Range(found, in: attributed) {
                attributed[range].backgroundColor = .yellow.opacity(0.6)
                attributed[range].foregroundColor = .black
            }
            searchRange = found.upperBound..<text.endIndex
        }
        return attributed
    }
}

#Preview {
    LogLinesView(
        lines: (0..<10_000).map { LogLine(id: $0, text: "2026/11/01 12:00:\(String(format: "%02d", $0 % 60)).123 [http-nio-58080-exec-\($0 % 9) Sample.java:\($0)] \(["INFO", "WARN", "ERROR", "DEBUG"][$0 % 4]) c.g.Sample - line \($0) {\"id\":\($0),\"ok\":true} 97ms") },
        searchQuery: "line 99",
        wrap: true,
        follow: .constant(false)
    )
}
