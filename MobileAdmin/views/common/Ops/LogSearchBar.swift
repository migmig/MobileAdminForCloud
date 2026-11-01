//
//  LogSearchBar.swift
//  MobileAdmin
//
//  로그 본문 검색 — 일치 줄 목록 계산과 이전/다음 이동
//

import SwiftUI

/// 검색 상태 (일치하는 줄 id 목록과 현재 위치)
struct LogSearchState: Equatable {
    var query = ""
    private(set) var matches: [LogLine.ID] = []
    private(set) var currentIndex = 0

    var currentID: LogLine.ID? {
        matches.indices.contains(currentIndex) ? matches[currentIndex] : nil
    }

    /// "3/12" 형식 표시
    var positionText: String {
        matches.isEmpty ? "0/0" : "\(currentIndex + 1)/\(matches.count)"
    }

    /// 일치 목록 재계산 — 가능하면 현재 위치의 줄을 유지한다
    mutating func recompute(in lines: [LogLine]) {
        let previousID = currentID
        guard !query.isEmpty else {
            matches = []
            currentIndex = 0
            return
        }
        matches = lines.compactMap { line in
            line.text.range(of: query, options: .caseInsensitive) != nil ? line.id : nil
        }
        if let previousID, let index = matches.firstIndex(of: previousID) {
            currentIndex = index
        } else {
            // 처음 검색하면 가장 최근(마지막) 일치 위치로
            currentIndex = max(matches.count - 1, 0)
        }
    }

    mutating func next() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex + 1) % matches.count
    }

    mutating func previous() {
        guard !matches.isEmpty else { return }
        currentIndex = (currentIndex - 1 + matches.count) % matches.count
    }
}

struct LogSearchBar: View {
    @Binding var state: LogSearchState
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("로그 검색", text: $state.query)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit { state.next() }

            Text(state.positionText)
                .font(AppFont.monoDigit)
                .foregroundStyle(.secondary)

            Button { state.previous() } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(state.matches.isEmpty)
            .accessibilityLabel("이전 일치")

            Button { state.next() } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(state.matches.isEmpty)
            .accessibilityLabel("다음 일치")

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("검색 닫기")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
