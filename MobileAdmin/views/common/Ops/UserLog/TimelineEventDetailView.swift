//
//  TimelineEventDetailView.swift
//  MobileAdmin
//
//  인터페이스 흐름 이벤트 상세 — 메타, 헤더, 메시지, 요청/응답 본문(JSON 정렬 + 복사)
//

import SwiftUI

struct TimelineEventDetailView: View {
    let event: TimelineEvent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.sm) {
                    TimelineKindChip(event: event)
                    Text(event.displayTitle)
                        .font(AppFont.listTitle)
                        .textSelection(.enabled)
                    Spacer(minLength: 0)
                    TimelineStatusBadge(event: event)
                }

                metaGrid

                if let header = event.header, !header.isEmpty {
                    TimelineTextBlock(text: header, tint: .secondary)
                }
                if let message = event.message, !message.isEmpty {
                    TimelineTextBlock(text: message, tint: .orange)
                }
                if event.kind != .log {
                    bodies
                }
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(event.interfaceId ?? event.kindLabel)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - 메타

    private var meta: [(String, String)] {
        [
            ("IF ID", event.interfaceId),
            ("명칭", event.name),
            ("시작", event.start),
            ("종료", event.end),
            ("소요", event.elapsedMs.map { TimelineFormat.duration($0) }),
            ("스레드", event.thread),
            ("HTTP", event.httpStatus),
            ("RLT_CODE", event.resultCode),
            ("RLT_MSG", event.resultMsg),
            ("소스", event.source),
        ].compactMap { key, value in
            guard let value, !value.isEmpty else { return nil }
            return (key, value)
        }
    }

    private var metaGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: AppSpacing.md, verticalSpacing: AppSpacing.xs) {
            ForEach(meta, id: \.0) { key, value in
                GridRow {
                    Text(key)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(AppFont.mono)
                        .textSelection(.enabled)
                }
            }
        }
    }

    // MARK: - 요청 / 응답

    @ViewBuilder
    private var bodies: some View {
        #if os(macOS)
        HStack(alignment: .top, spacing: AppSpacing.md) {
            TimelineBodyPanel(title: "요청 →", text: event.request)
            TimelineBodyPanel(title: "← 응답", text: event.response)
        }
        #else
        TimelineBodyPanel(title: "요청 →", text: event.request)
        TimelineBodyPanel(title: "← 응답", text: event.response)
        #endif
    }
}

// MARK: - 본문 패널

struct TimelineBodyPanel: View {
    let title: String
    let text: String?

    @State private var copied = false

    private var pretty: String { TimelineFormat.prettyBody(text) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !pretty.isEmpty {
                    Button {
                        Util.copyToClipboard(pretty)
                        copied = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            copied = false
                        }
                    } label: {
                        Label(copied ? "복사됨" : "복사", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(AppFont.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            if pretty.isEmpty {
                Text("(기록 없음)")
                    .font(AppFont.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.sm)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.xs))
            } else {
                TimelineTextBlock(text: pretty, tint: .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

/// 고정폭 텍스트 블록 (선택 가능)
struct TimelineTextBlock: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(verbatim: text)
            .font(AppFont.mono)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.sm)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.xs))
    }
}

#Preview {
    NavigationStack {
        TimelineEventDetailView(event: TimelineEvent(
            seq: 2, status: .fail, start: "2026-11-03 09:00:00.200", startMs: 100,
            end: "2026-11-03 09:00:01.050", elapsedMs: 850, source: "EsbInterfaceV2",
            interfaceId: "IF_UTC_MDS_001", name: "사용자 정보 조회", httpStatus: "200",
            resultCode: "E001", resultMsg: "조회 실패",
            request: #"{"USER_ID":"UT00000109114","SEQ":"1"}"#,
            response: #"{"RLT_CODE":"E001","RLT_MSG":"조회 실패"}"#))
    }
}
