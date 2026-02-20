import SwiftUI

/// Request Info 상세 뷰 - JSON 형태의 요청 정보를 구조화하여 표시
struct RequestInfoDetailView: View {
    let requestInfo: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var searchText: String = ""
    @State private var currentMatchIndex: Int = 0
    @State private var wordWrap: Bool = true
    @State private var showCopied: Bool = false

    private var formattedContent: String {
        Util.formatRequestInfo(requestInfo)
    }

    private var lines: [String] {
        formattedContent.components(separatedBy: "\n")
    }

    private var matchingLineIndices: [Int] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return lines.enumerated().compactMap { index, line in
            line.lowercased().contains(query) ? index : nil
        }
    }

    private var totalMatches: Int { matchingLineIndices.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                contentView
            }
            .navigationTitle("Request Info 상세")
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
                .onChange(of: searchText) { _, _ in currentMatchIndex = 0 }

            if !searchText.isEmpty {
                Text("\(totalMatches > 0 ? currentMatchIndex + 1 : 0)/\(totalMatches)")
                    .font(AppFont.captionSmall)
                    .foregroundColor(.secondary)
                    .monospacedDigit()

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

                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .cardBackground()
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollViewReader { proxy in
            ScrollView(wordWrap ? [.vertical] : [.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        lineRow(line: line, index: index)
                            .id(index)
                    }
                }
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: wordWrap ? .infinity : nil, alignment: .leading)
            }
            .onChange(of: currentMatchIndex) { _, newIndex in
                if totalMatches > 0, newIndex < matchingLineIndices.count {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(matchingLineIndices[newIndex], anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Line Row

    private func lineRow(line: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // 줄 번호
            Text("\(index + 1)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.5))
                .frame(width: 44, alignment: .trailing)
                .padding(.trailing, AppSpacing.sm)

            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 1)

            Group {
                if !searchText.isEmpty, line.lowercased().contains(searchText.lowercased()) {
                    let isCurrent = matchingLineIndices.indices.contains(currentMatchIndex)
                        && matchingLineIndices[currentMatchIndex] == index
                    Text(buildHighlightedString(line, query: searchText, isCurrent: isCurrent))
                        .font(.system(.caption, design: .monospaced))
                } else {
                    Text(coloredJSONLine(line))
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .textSelection(.enabled)
            .padding(.leading, AppSpacing.sm)
            .frame(maxWidth: wordWrap ? .infinity : nil, alignment: .leading)
            .fixedSize(horizontal: !wordWrap, vertical: false)
        }
        .padding(.vertical, 1)
        .background(
            Group {
                if !searchText.isEmpty,
                   matchingLineIndices.indices.contains(currentMatchIndex),
                   matchingLineIndices[currentMatchIndex] == index {
                    Color.orange.opacity(0.1)
                } else {
                    Color.clear
                }
            }
        )
    }

    // MARK: - JSON 구문 색상

    /// 한 줄의 JSON 내용을 파싱하여 키/값 색상이 적용된 AttributedString 반환
    private func coloredJSONLine(_ line: String) -> AttributedString {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 순수 구조 라인: {  }  [  ]
        if isStructuralLine(trimmed) {
            var attr = AttributedString(line)
            attr.font = .system(.caption, design: .monospaced)
            attr.foregroundColor = .secondary
            return attr
        }

        // "key" : value 패턴 탐색
        if let colonRange = findKeyColonSeparator(in: line) {
            var result = AttributedString()

            // 키 부분 (콜론 앞)
            var keyAttr = AttributedString(String(line[line.startIndex..<colonRange.lowerBound]))
            keyAttr.font = .system(.caption, design: .monospaced)
            keyAttr.foregroundColor = Color.blue.opacity(0.85)
            result.append(keyAttr)

            // 콜론
            var colonAttr = AttributedString(String(line[colonRange]))
            colonAttr.font = .system(.caption, design: .monospaced)
            colonAttr.foregroundColor = .secondary
            result.append(colonAttr)

            // 값 부분 (콜론 뒤)
            let valuePart = String(line[colonRange.upperBound...])
            var valueAttr = AttributedString(valuePart)
            valueAttr.font = .system(.caption, design: .monospaced)
            valueAttr.foregroundColor = valueColor(for: valuePart)
            result.append(valueAttr)

            return result
        }

        // 매칭 없는 일반 라인
        var attr = AttributedString(line)
        attr.font = .system(.caption, design: .monospaced)
        attr.foregroundColor = .primary
        return attr
    }

    private func isStructuralLine(_ trimmed: String) -> Bool {
        let structurals = ["{", "}", "[", "]", "},", "],"]
        return structurals.contains(trimmed)
    }

    /// `"key"` 뒤에 오는 `:` 범위 반환
    private func findKeyColonSeparator(in line: String) -> Range<String.Index>? {
        var idx = line.startIndex

        // 들여쓰기 건너뜀
        while idx < line.endIndex && line[idx].isWhitespace {
            idx = line.index(after: idx)
        }

        // 시작 `"` 확인
        guard idx < line.endIndex, line[idx] == "\"" else { return nil }
        idx = line.index(after: idx)

        // 닫는 `"` 찾기 (이스케이프 고려)
        while idx < line.endIndex {
            if line[idx] == "\\" {
                idx = line.index(after: idx) // 이스케이프 문자 건너뜀
                if idx < line.endIndex { idx = line.index(after: idx) }
            } else if line[idx] == "\"" {
                idx = line.index(after: idx) // 닫는 " 통과
                break
            } else {
                idx = line.index(after: idx)
            }
        }

        // 공백 건너뜀
        while idx < line.endIndex && line[idx].isWhitespace {
            idx = line.index(after: idx)
        }

        // `:` 확인
        guard idx < line.endIndex, line[idx] == ":" else { return nil }
        let colonStart = idx
        let colonEnd = line.index(after: idx)
        return colonStart..<colonEnd
    }

    /// 값 문자열의 타입에 따른 색상 반환
    private func valueColor(for value: String) -> Color {
        let trimmed = value
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: ","))
            .trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("\"") { return Color(red: 0.1, green: 0.6, blue: 0.1) }   // 문자열 -> 초록
        if trimmed == "null"        { return .secondary }                                // null -> 회색
        if trimmed == "true" || trimmed == "false" { return .orange }                    // boolean -> 주황
        return Color.purple.opacity(0.8)                                                  // 숫자 -> 보라
    }

    // MARK: - Search Highlight

    private func buildHighlightedString(_ text: String, query: String, isCurrent: Bool) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = .secondary
        attributed.font = .system(.caption, design: .monospaced)

        var searchStart = text.startIndex
        while searchStart < text.endIndex,
              let range = text.range(of: query, options: .caseInsensitive, range: searchStart..<text.endIndex) {
            let attrStart = AttributedString.Index(range.lowerBound, within: attributed)
            let attrEnd   = AttributedString.Index(range.upperBound, within: attributed)
            if let s = attrStart, let e = attrEnd {
                attributed[s..<e].backgroundColor = isCurrent ? .orange : .yellow.opacity(0.4)
                attributed[s..<e].foregroundColor  = isCurrent ? .white  : .primary
                if isCurrent {
                    attributed[s..<e].font = .system(.caption, design: .monospaced, weight: .bold)
                }
            }
            searchStart = range.upperBound
        }
        return attributed
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("닫기") { dismiss() }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                withAnimation { wordWrap.toggle() }
            } label: {
                Image(systemName: wordWrap ? "text.alignleft" : "arrow.left.and.right")
            }
            .help(wordWrap ? "줄바꿈 끄기" : "줄바꿈 켜기")

            Button {
                Util.copyToClipboard(formattedContent)
                showCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showCopied = false }
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
}

// MARK: - Preview

#Preview {
    RequestInfoDetailView(requestInfo: """
    {"userId":"testUser","method":"POST","url":"/api/v1/login","body":{"name":"홍길동","age":30,"active":true,"score":null,"token":"eyJhbGciOiJIUzI1NiJ9"},"headers":{"Content-Type":"application/json","Accept":"*/*"}}
    """)
}
