import SwiftUI

/// Trace 상세 뷰 - 스택트레이스를 구조화하여 표시
struct TraceDetailView: View {
    let traceContent: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var searchText: String = ""
    @State private var currentMatchIndex: Int = 0
    @State private var wordWrap: Bool = true
    @State private var collapseAtBlocks: Bool = false
    @State private var showCopied: Bool = false

    private var lines: [TraceLine] {
        let rawLines = traceContent.components(separatedBy: "\n")
        return rawLines.enumerated().map { index, content in
            TraceLine(
                lineNumber: index + 1,
                content: content,
                kind: classifyLine(content)
            )
        }
    }

    private var visibleLines: [TraceLine] {
        if collapseAtBlocks {
            return collapseConsecutiveAtLines(lines)
        }
        return lines
    }

    private var matchingLineIndices: [Int] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return visibleLines.enumerated().compactMap { index, line in
            line.content.lowercased().contains(query) ? index : nil
        }
    }

    private var totalMatches: Int { matchingLineIndices.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
                searchBar

                Divider()

                // MARK: - Trace Content
                traceContentView
            }
            .navigationTitle("Trace 상세")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarItems }
        }
        #if os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        #endif
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.caption)

            TextField("검색...", text: $searchText)
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .onChange(of: searchText) { _, _ in
                    currentMatchIndex = 0
                }

            if !searchText.isEmpty {
                // Match counter
                Text("\(totalMatches > 0 ? currentMatchIndex + 1 : 0)/\(totalMatches)")
                    .font(AppFont.captionSmall)
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                // Prev / Next
                Button { navigateMatch(direction: -1) } label: {
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.semibold))
                }
                .disabled(totalMatches == 0)

                Button { navigateMatch(direction: 1) } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .disabled(totalMatches == 0)

                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .cardBackground()
    }

    // MARK: - Trace Content
    private var traceContentView: some View {
        ScrollViewReader { proxy in
            ScrollView(wordWrap ? [.vertical] : [.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(visibleLines.enumerated()), id: \.offset) { index, line in
                        traceLineRow(line: line, index: index)
                            .id(index)
                    }
                }
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: wordWrap ? .infinity : nil, alignment: .leading)
            }
            .onChange(of: currentMatchIndex) { _, newIndex in
                if totalMatches > 0 {
                    let targetIndex = matchingLineIndices[newIndex]
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(targetIndex, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Single Line Row
    private func traceLineRow(line: TraceLine, index: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Line number
            Text(line.isCollapsedPlaceholder ? "..." : "\(line.lineNumber)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.5))
                .frame(width: 44, alignment: .trailing)
                .padding(.trailing, AppSpacing.sm)

            // Separator
            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 1)

            // Content
            if line.isCollapsedPlaceholder {
                collapsedPlaceholder(count: line.collapsedCount)
                    .padding(.leading, AppSpacing.sm)
            } else {
                highlightedText(line: line, index: index)
                    .padding(.leading, AppSpacing.sm)
            }
        }
        .padding(.vertical, 1)
        .background(lineBackground(line: line, index: index))
    }

    // MARK: - Highlighted Text
    private func highlightedText(line: TraceLine, index: Int) -> some View {
        Group {
            if !searchText.isEmpty, line.content.lowercased().contains(searchText.lowercased()) {
                let isCurrentMatch = matchingLineIndices.indices.contains(currentMatchIndex)
                    && matchingLineIndices[currentMatchIndex] == index
                Text(buildHighlightedString(line.content, query: searchText, isCurrent: isCurrentMatch))
                    .font(.system(.caption, design: .monospaced))
            } else {
                Text(line.content)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(lineColor(for: line.kind))
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: wordWrap ? .infinity : nil, alignment: .leading)
        .fixedSize(horizontal: !wordWrap, vertical: false)
    }

    // MARK: - Search Highlight (AttributedString)
    private func buildHighlightedString(_ text: String, query: String, isCurrent: Bool) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = .secondary
        attributed.font = .system(.caption, design: .monospaced)

        let textLowered = text.lowercased()
        let queryLowered = query.lowercased()
        var searchStart = textLowered.startIndex

        while searchStart < textLowered.endIndex,
              let range = textLowered.range(of: queryLowered, range: searchStart..<textLowered.endIndex) {
            // Convert String.Index to AttributedString.Index
            let attrStart = AttributedString.Index(range.lowerBound, within: attributed)
            let attrEnd = AttributedString.Index(range.upperBound, within: attributed)

            if let attrStart = attrStart, let attrEnd = attrEnd {
                attributed[attrStart..<attrEnd].backgroundColor = isCurrent ? .orange : .yellow.opacity(0.4)
                attributed[attrStart..<attrEnd].foregroundColor = isCurrent ? .white : .primary
                if isCurrent {
                    attributed[attrStart..<attrEnd].font = .system(.caption, design: .monospaced).bold()
                }
            }

            searchStart = range.upperBound
        }

        return attributed
    }

    // MARK: - Collapsed "at" Placeholder
    private func collapsedPlaceholder(count: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                collapseAtBlocks = false
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "ellipsis")
                Text("\(count)개 프레임 숨김 — 펼치기")
            }
            .font(.system(.caption2, design: .monospaced))
            .foregroundColor(.accentColor)
            .padding(.vertical, AppSpacing.xxs)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Line Background
    private func lineBackground(line: TraceLine, index: Int) -> some View {
        Group {
            if !searchText.isEmpty,
               matchingLineIndices.indices.contains(currentMatchIndex),
               matchingLineIndices[currentMatchIndex] == index {
                Color.orange.opacity(0.1)
            } else {
                switch line.kind {
                case .exception:
                    Color.red.opacity(0.08)
                case .causedBy:
                    Color.orange.opacity(0.08)
                default:
                    Color.clear
                }
            }
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("닫기") { dismiss() }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            // Word wrap toggle
            Button {
                withAnimation { wordWrap.toggle() }
            } label: {
                Image(systemName: wordWrap ? "text.word.spacing" : "arrow.left.and.right.text.vertical")
            }
            .help(wordWrap ? "줄바꿈 끄기" : "줄바꿈 켜기")

            // Collapse toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { collapseAtBlocks.toggle() }
            } label: {
                Image(systemName: collapseAtBlocks ? "list.bullet.indent" : "list.bullet")
            }
            .help(collapseAtBlocks ? "전체 펼치기" : "at 블록 접기")

            // Copy
            Button {
                Util.copyToClipboard(traceContent)
                showCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showCopied = false
                }
            } label: {
                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
            }
            .help("전체 복사")
        }
    }

    // MARK: - Navigation
    private func navigateMatch(direction: Int) {
        guard totalMatches > 0 else { return }
        currentMatchIndex = (currentMatchIndex + direction + totalMatches) % totalMatches
    }

    // MARK: - Line Classification
    private func classifyLine(_ line: String) -> TraceLineKind {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("Caused by") {
            return .causedBy
        }
        if trimmed.contains("Exception") || trimmed.contains("Error") {
            // at 라인 안의 Exception/Error 클래스명은 제외
            if trimmed.hasPrefix("at ") || trimmed.hasPrefix("\t") {
                return .atFrame
            }
            return .exception
        }
        if trimmed.hasPrefix("at ") || trimmed.hasPrefix("...") {
            return .atFrame
        }
        return .plain
    }

    // MARK: - Collapse Logic
    private func collapseConsecutiveAtLines(_ allLines: [TraceLine]) -> [TraceLine] {
        var result: [TraceLine] = []
        var atCount = 0
        var firstAtLine: TraceLine?

        for line in allLines {
            if line.kind == .atFrame {
                if atCount == 0 {
                    firstAtLine = line
                }
                atCount += 1
            } else {
                if atCount > 0 {
                    // Keep first 2, collapse rest
                    if atCount <= 3 {
                        // Not worth collapsing, show all
                        let startNum = (firstAtLine?.lineNumber ?? 1)
                        for i in 0..<atCount {
                            let original = allLines.first { $0.lineNumber == startNum + i }
                            if let original = original {
                                result.append(original)
                            }
                        }
                    } else {
                        // Show first 2, collapse the rest
                        let startNum = (firstAtLine?.lineNumber ?? 1)
                        for i in 0..<2 {
                            let original = allLines.first { $0.lineNumber == startNum + i }
                            if let original = original {
                                result.append(original)
                            }
                        }
                        result.append(TraceLine(
                            lineNumber: startNum + 2,
                            content: "",
                            kind: .atFrame,
                            isCollapsedPlaceholder: true,
                            collapsedCount: atCount - 2
                        ))
                    }
                    atCount = 0
                    firstAtLine = nil
                }
                result.append(line)
            }
        }

        // Handle trailing at-block
        if atCount > 0 {
            let startNum = (firstAtLine?.lineNumber ?? 1)
            if atCount <= 3 {
                for i in 0..<atCount {
                    let original = allLines.first { $0.lineNumber == startNum + i }
                    if let original = original { result.append(original) }
                }
            } else {
                for i in 0..<2 {
                    let original = allLines.first { $0.lineNumber == startNum + i }
                    if let original = original { result.append(original) }
                }
                result.append(TraceLine(
                    lineNumber: startNum + 2,
                    content: "",
                    kind: .atFrame,
                    isCollapsedPlaceholder: true,
                    collapsedCount: atCount - 2
                ))
            }
        }

        return result
    }

    // MARK: - Color
    private func lineColor(for kind: TraceLineKind) -> Color {
        switch kind {
        case .exception: return AppColor.error
        case .causedBy:  return .orange
        case .atFrame:   return .secondary
        case .plain:     return .primary
        }
    }
}

// MARK: - Models

enum TraceLineKind {
    case exception   // Exception/Error 메인 라인
    case causedBy    // Caused by 라인
    case atFrame     // at 스택프레임
    case plain       // 기타
}

struct TraceLine {
    let lineNumber: Int
    let content: String
    let kind: TraceLineKind
    var isCollapsedPlaceholder: Bool = false
    var collapsedCount: Int = 0
}

// MARK: - Preview

#Preview("Java Stack Trace") {
    TraceDetailView(traceContent: """
    java.lang.NullPointerException: Cannot invoke method on null object
        at com.example.service.UserService.getUser(UserService.java:42)
        at com.example.service.UserService.findByEmail(UserService.java:87)
        at com.example.controller.UserController.login(UserController.java:35)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:205)
        at org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:897)
    Caused by: java.sql.SQLException: Connection refused
        at com.mysql.cj.jdbc.ConnectionImpl.createNewIO(ConnectionImpl.java:836)
        at com.mysql.cj.jdbc.ConnectionImpl.<init>(ConnectionImpl.java:456)
        at com.example.dao.UserDao.findById(UserDao.java:23)
        at com.example.dao.UserDao.findByEmail(UserDao.java:45)
    Caused by: java.net.ConnectException: Connection refused (Connection refused)
        at java.net.PlainSocketImpl.socketConnect(Native Method)
        at java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:350)
    """)
}
