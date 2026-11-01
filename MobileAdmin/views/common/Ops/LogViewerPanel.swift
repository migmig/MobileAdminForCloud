//
//  LogViewerPanel.swift
//  MobileAdmin
//
//  로그 뷰어 패널 — 컨트롤 바(검색/줄바꿈/따라가기/복사 + 화면별 추가 버튼) + 검색 바 + 본문
//

import SwiftUI

struct LogViewerPanel<Accessory: View>: View {
    let lines: [LogLine]
    /// nil이면 따라가기 토글을 표시하지 않는다 (정적 내용)
    var follow: Binding<Bool>?
    var emptyTitle: String = "표시할 로그가 없습니다"
    var emptyDescription: String? = nil
    @ViewBuilder var accessory: () -> Accessory

    @State private var wrap = true
    @State private var isSearching = false
    @State private var search = LogSearchState()
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            controlBar
            Divider()
            if isSearching {
                LogSearchBar(state: $search) {
                    isSearching = false
                    search.query = ""
                }
                Divider()
            }
            if lines.isEmpty {
                EmptyStateView(systemImage: "text.alignleft", title: emptyTitle, description: emptyDescription)
                    .frame(maxHeight: .infinity)
            } else {
                LogLinesView(lines: lines,
                             searchQuery: isSearching ? search.query : "",
                             currentMatchID: isSearching ? search.currentID : nil,
                             wrap: wrap,
                             follow: follow ?? .constant(false))
            }
        }
        // 검색어 입력은 250ms debounce 후 재계산
        .task(id: search.query) {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            search.recompute(in: lines)
        }
        // 새 줄이 들어오면 재계산 (tail)
        .onChange(of: lines.last?.id) { _, _ in
            if isSearching, !search.query.isEmpty {
                search.recompute(in: lines)
            }
        }
    }

    private var controlBar: some View {
        HStack(spacing: AppSpacing.md) {
            accessory()

            Spacer(minLength: AppSpacing.sm)

            Text("\(lines.count)줄")
                .font(AppFont.monoDigit)
                .foregroundStyle(.secondary)

            if let follow {
                Toggle(isOn: follow) {
                    Image(systemName: "arrow.down.to.line")
                }
                .toggleStyle(.button)
                .help("하단 따라가기")
                .accessibilityLabel("하단 따라가기")
            }

            Toggle(isOn: $isSearching) {
                Image(systemName: "magnifyingglass")
            }
            .toggleStyle(.button)
            .help("검색")
            .accessibilityLabel("검색")

            Toggle(isOn: $wrap) {
                Image(systemName: "text.word.spacing")
            }
            .toggleStyle(.button)
            .help("줄바꿈")
            .accessibilityLabel("줄바꿈")

            Button {
                Util.copyToClipboard(lines.map(\.text).joined(separator: "\n"))
                copied = true
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
            }
            .disabled(lines.isEmpty)
            .help("전체 복사")
            .accessibilityLabel("전체 복사")
            .task(id: copied) {
                guard copied else { return }
                try? await Task.sleep(for: .seconds(1.5))
                copied = false
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

extension LogViewerPanel where Accessory == EmptyView {
    init(lines: [LogLine],
         follow: Binding<Bool>? = nil,
         emptyTitle: String = "표시할 로그가 없습니다",
         emptyDescription: String? = nil) {
        self.init(lines: lines, follow: follow, emptyTitle: emptyTitle, emptyDescription: emptyDescription) {
            EmptyView()
        }
    }
}

#Preview {
    LogViewerPanel(lines: (0..<500).map { LogLine(id: $0, text: "line \($0) ERROR sample") })
}
