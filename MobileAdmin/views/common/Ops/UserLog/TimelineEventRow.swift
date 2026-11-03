//
//  TimelineEventRow.swift
//  MobileAdmin
//
//  인터페이스 흐름 목록 구성 요소 — 이벤트 행, 종류 칩, 상태 배지, 세션/요청 묶음 헤더
//

import SwiftUI

// MARK: - 색

extension TimelineEvent {
    /// 종류 칩 색 (웹과 같은 계열)
    var kindTint: Color {
        switch kind {
        case .esb:     return .blue
        case .midas:   return .purple
        case .api:     return .green
        case .log:     return level == "ERROR" ? .red : .orange
        case .unknown: return .gray
        }
    }

    var kindLabel: String {
        switch kind {
        case .log:     return level ?? "LOG"
        case .api:     return "API"
        default:       return kind.label
        }
    }
}

// MARK: - 종류 칩 / 상태 배지

struct TimelineKindChip: View {
    let event: TimelineEvent

    var body: some View {
        Text(event.kindLabel)
            .font(AppFont.captionSmall.weight(.semibold))
            .foregroundStyle(event.kindTint)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 1)
            .background(event.kindTint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.xs / 2))
    }
}

struct TimelineStatusBadge: View {
    let event: TimelineEvent

    var body: some View {
        switch (event.status, event.kind) {
        case (.fail, _):
            OpsTag(text: event.resultCode.map { "실패 \($0)" } ?? "실패", tint: .red)
        case (.incomplete, _):
            OpsTag(text: "응답 미기록", tint: .orange)
        case (.info, .api):
            OpsTag(text: "진입")
        default:
            EmptyView()
        }
    }
}

// MARK: - 이벤트 행

struct TimelineEventRow: View {
    let event: TimelineEvent
    /// 연계 호출 소요시간 막대의 기준 (같은 날짜 최대 응답시간)
    var maxElapsedMs: Int64 = 0
    var isSelected = false

    var body: some View {
        #if os(macOS)
        HStack(spacing: AppSpacing.sm) {
            Text(TimelineFormat.timeOfDay(event.start))
                .font(AppFont.mono)
                .foregroundStyle(.secondary)
            TimelineKindChip(event: event)
                .frame(width: 56, alignment: .leading)
            title
            Spacer(minLength: AppSpacing.sm)
            Text(TimelineFormat.shortThread(event.thread))
                .font(AppFont.mono)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .help(event.thread)
            elapsed
                .frame(width: 120, alignment: .trailing)
            TimelineStatusBadge(event: event)
                .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.sm)
        .background(selectionBackground)
        .contentShape(Rectangle())
        #else
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack(spacing: AppSpacing.xs) {
                Text(TimelineFormat.timeOfDay(event.start))
                    .font(AppFont.mono)
                    .foregroundStyle(.secondary)
                TimelineKindChip(event: event)
                Spacer(minLength: AppSpacing.xs)
                if event.elapsedMs != nil {
                    Text(TimelineFormat.duration(event.elapsedMs))
                        .font(AppFont.monoDigit)
                        .foregroundStyle(.secondary)
                }
                TimelineStatusBadge(event: event)
            }
            title
        }
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.md)
        .background(selectionBackground)
        .contentShape(Rectangle())
        #endif
    }

    private var title: some View {
        HStack(spacing: AppSpacing.xs) {
            if let interfaceId = event.interfaceId, interfaceId != event.name {
                Text(interfaceId)
                    .font(AppFont.mono)
                    .lineLimit(1)
            }
            if let name = event.name ?? (event.interfaceId == nil ? event.message ?? event.source : nil) {
                Text(name)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .truncationMode(.tail)
    }

    /// 소요시간 + (연계 호출이면) 최대 응답시간 대비 막대
    private var elapsed: some View {
        HStack(spacing: AppSpacing.xs) {
            if event.isCall, let ms = event.elapsedMs, maxElapsedMs > 0 {
                GeometryReader { proxy in
                    Capsule()
                        .fill(event.status == .fail ? Color.red.opacity(0.5) : Color.blue.opacity(0.35))
                        .frame(width: max(2, proxy.size.width * CGFloat(ms) / CGFloat(maxElapsedMs)), height: 4)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: 48, height: 10)
            }
            Text(TimelineFormat.duration(event.elapsedMs))
                .font(AppFont.monoDigit)
                .foregroundStyle(event.elapsedMs == nil ? .tertiary : .secondary)
        }
    }

    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.xs)
            .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}

// MARK: - 세션 헤더

struct TimelineSessionHeader: View {
    let session: TimelineSession

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("\(TimelineFormat.clock(session.startMs)) ~ \(TimelineFormat.clock(session.endMs))")
                .font(AppFont.mono.weight(.semibold))
            Text(TimelineFormat.duration(session.endMs - session.startMs))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: AppSpacing.xs)
            Text("호출 \(session.callCount)건")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            if session.failCount > 0 {
                OpsTag(text: "실패 \(session.failCount)", tint: .red)
            }
            if session.incompleteCount > 0 {
                OpsTag(text: "미기록 \(session.incompleteCount)", tint: .orange)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }
}

// MARK: - 세션 시간 막대 (macOS)

/// 세션 구간 안에서 이벤트 위치와 길이를 막대로 표시 — 누르면 그 이벤트로 이동
struct TimelineSessionStrip: View {
    let session: TimelineSession
    var selectedSeq: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        let span = Double(max(session.endMs - session.startMs, 1))
        // 연계 호출·API 진입과 실패 로그만 (WARN 로그는 제외)
        let marks = session.events.filter { $0.kind != .log || $0.status == .fail }

        VStack(spacing: AppSpacing.xxs) {
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppRadius.xs / 2)
                        .fill(Color.secondary.opacity(0.1))
                    ForEach(marks) { event in
                        let left = min(Double(event.startMs - session.startMs) / span, 0.996) * width
                        let isApi = event.kind == .api
                        let barWidth = isApi ? 2 : max(Double(event.elapsedMs ?? 0) / span * width, 3)
                        Rectangle()
                            .fill(isApi ? Color.green : statusColor(event.status))
                            .frame(width: barWidth, height: isApi ? 22 : 14)
                            .opacity(selectedSeq == event.seq ? 1 : 0.7)
                            .overlay {
                                if selectedSeq == event.seq {
                                    Rectangle().stroke(Color.accentColor, lineWidth: 2)
                                }
                            }
                            .offset(x: left)
                            .onTapGesture { onSelect(event.seq) }
                            .help("\(TimelineFormat.timeOfDay(event.start)) \(event.interfaceId ?? "") \(event.name ?? "") \(TimelineFormat.duration(event.elapsedMs))")
                    }
                }
            }
            .frame(height: 22)

            HStack {
                Text(TimelineFormat.clock(session.startMs))
                Spacer()
                Text(TimelineFormat.clock(session.endMs))
            }
            .font(.system(size: 10).monospacedDigit())
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
    }

    private func statusColor(_ status: TimelineStatus) -> Color {
        switch status {
        case .fail:       return .red
        case .incomplete: return .orange
        default:          return .blue
        }
    }
}

// MARK: - 요청 묶음 헤더

struct TimelineGroupHeader: View {
    let group: TimelineRequestGroup
    let isCollapsed: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(AppFont.captionSmall.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 12)
                Text(TimelineFormat.clock(group.startMs))
                    .font(AppFont.mono)
                    .foregroundStyle(.secondary)
                Text(TimelineFormat.shortThread(group.thread))
                    .font(AppFont.mono)
                    .padding(.horizontal, AppSpacing.xs)
                    .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: AppRadius.xs / 2))
                    .help(group.thread)
                Text(entryTitle)
                    .font(AppFont.caption.weight(group.entry == nil ? .regular : .semibold))
                    .foregroundStyle(group.entry == nil ? .secondary : .primary)
                    .lineLimit(1)
                Spacer(minLength: AppSpacing.xs)
                Text("\(group.events.count)건 · 연계 \(group.callCount)")
                    .font(AppFont.captionSmall)
                    .foregroundStyle(.secondary)
                Text(TimelineFormat.duration(group.endMs - group.startMs))
                    .font(AppFont.monoDigit)
                    .foregroundStyle(.secondary)
                if group.failCount > 0 {
                    OpsTag(text: "실패 \(group.failCount)", tint: .red)
                }
                if group.incompleteCount > 0 {
                    OpsTag(text: "미기록 \(group.incompleteCount)", tint: .orange)
                }
            }
            .padding(.vertical, AppSpacing.xs)
            .padding(.horizontal, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entryTitle) 묶음 \(isCollapsed ? "펼치기" : "접기")")
    }

    private var entryTitle: String {
        guard let entry = group.entry else { return "같은 스레드 연속 처리" }
        return entry.name ?? entry.interfaceId ?? "API"
    }
}

#Preview {
    let events = [
        TimelineEvent(seq: 1, kind: .api, status: .info, start: "2026-11-03 09:00:00.100", startMs: 0, elapsedMs: 1200,
                      interfaceId: "LoginController.login", name: "로그인"),
        TimelineEvent(seq: 2, status: .fail, start: "2026-11-03 09:00:00.200", startMs: 100, elapsedMs: 850,
                      interfaceId: "IF_UTC_MDS_001", name: "사용자 정보 조회", resultCode: "E001"),
        TimelineEvent(seq: 3, kind: .midas, status: .incomplete, start: "2026-11-03 09:00:00.900", startMs: 800,
                      interfaceId: "MDS_002", name: "MIDAS 연계"),
        TimelineEvent(seq: 4, kind: .log, status: .fail, start: "2026-11-03 09:00:01.000", startMs: 900,
                      level: "ERROR", name: "EsbServiceImpl", message: "NullPointerException"),
    ]
    let group = TimelineAnalysis.requestGroups(events)[0]
    return VStack(spacing: 0) {
        TimelineSessionHeader(session: TimelineAnalysis.sessions(events)[0])
        TimelineGroupHeader(group: group, isCollapsed: false) {}
        ForEach(events) { event in
            TimelineEventRow(event: event, maxElapsedMs: 850, isSelected: event.seq == 2)
        }
    }
    .frame(width: 760)
}
