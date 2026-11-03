//
//  UserLogTimelineView.swift
//  MobileAdmin
//
//  사용자 로그 인터페이스 흐름 — 날짜 바, 요약, 필터, 세션별 이벤트 목록
//  iOS: 이벤트를 누르면 상세로 push / macOS: 오른쪽 inspector에 상세
//

import SwiftUI

struct UserLogTimelineView: View {
    @ObservedObject var model: UserLogTimelineModel

    var body: some View {
        VStack(spacing: 0) {
            if let data = model.data {
                header(data)
                Divider()
                content(data)
            } else {
                placeholder
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if os(macOS)
        .inspector(isPresented: inspectorBinding) {
            if let event = model.selectedEvent {
                TimelineEventDetailView(event: event)
                    .inspectorColumnWidth(min: 360, ideal: 460, max: 800)
            }
        }
        #endif
    }

    // MARK: - 결과 전 상태

    @ViewBuilder
    private var placeholder: some View {
        switch model.phase {
        case .idle:
            EmptyStateView(systemImage: "point.3.connected.trianglepath.dotted",
                           title: "인터페이스 흐름",
                           description: "사용자 번호를 입력하고 흐름 분석을 시작하세요.")
        case .loading, .loaded:
            ProgressView("로그를 분석하는 중...")
        case .failed:
            if let error = model.error {
                OpsErrorView(error: error,
                             notFoundHint: "사용자 번호와 로그 경로를 확인하세요.",
                             retry: model.reload)
            }
        }
    }

    // MARK: - 상단 (날짜, 안내, 요약, 필터)

    private func header(_ data: UserLogTimeline) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Label(data.file, systemImage: "doc.text")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if model.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }
                Button(action: model.reload) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(model.isLoading)
                .help("새로고침")
                .accessibilityLabel("새로고침")
            }

            if !data.isEmpty {
                TimelineDateBar(dates: data.dates, selected: data.date, onSelect: model.select(date:))
            }

            if data.truncated {
                OpsBanner(systemImage: "scissors",
                          text: "이벤트가 많아 마지막 \(UserLogTimeline.maxEventsPerDate)건만 표시합니다.")
            }
            if model.phase == .failed, let error = model.error {
                OpsBanner.error(error)
            }

            if !data.isEmpty {
                TimelineSummary(stats: model.stats, onFocusSlowest: model.focus(seq:))
                TimelineFilterBar(model: model)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - 목록

    @ViewBuilder
    private func content(_ data: UserLogTimeline) -> some View {
        if data.isEmpty {
            EmptyStateView(systemImage: "tray",
                           title: "인터페이스 이력이 없습니다.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.sections.isEmpty {
            VStack(spacing: AppSpacing.md) {
                EmptyStateView(systemImage: "line.3.horizontal.decrease.circle",
                               title: "조건에 맞는 이벤트가 없습니다.")
                if !model.filter.isDefault {
                    Button("필터 초기화", action: model.resetFilter)
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(model.sections) { section in
                            Section {
                                sectionRows(section)
                            } header: {
                                TimelineSessionHeader(session: section.session)
                            }
                        }
                    }
                    .padding(.bottom, AppSpacing.lg)
                }
                .onChange(of: model.scrollRequest) { _, request in
                    guard let request else { return }
                    withAnimation {
                        proxy.scrollTo(request.seq, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionRows(_ section: TimelineSection) -> some View {
        #if os(macOS)
        TimelineSessionStrip(session: section.session, selectedSeq: model.selectedSeq, onSelect: model.focus(seq:))
        #endif
        if let groups = section.groups {
            ForEach(groups) { group in
                let collapsed = model.collapsedGroups.contains(group.id)
                TimelineGroupHeader(group: group, isCollapsed: collapsed) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        model.toggleGroup(group.id)
                    }
                }
                .padding(.top, AppSpacing.xs)
                if !collapsed {
                    ForEach(group.events) { event in
                        row(event)
                            .padding(.leading, AppSpacing.lg)
                    }
                }
            }
        } else {
            ForEach(section.session.events) { event in
                row(event)
            }
        }
    }

    @ViewBuilder
    private func row(_ event: TimelineEvent) -> some View {
        let isSelected = model.selectedSeq == event.seq
        #if os(iOS)
        NavigationLink {
            TimelineEventDetailView(event: event)
        } label: {
            TimelineEventRow(event: event, maxElapsedMs: model.stats.maxElapsedMs, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { model.selectedSeq = event.seq })
        .id(event.seq)
        Divider().padding(.leading, AppSpacing.md)
        #else
        TimelineEventRow(event: event, maxElapsedMs: model.stats.maxElapsedMs, isSelected: isSelected)
            .onTapGesture { model.selectedSeq = event.seq }
            .id(event.seq)
        #endif
    }

    #if os(macOS)
    private var inspectorBinding: Binding<Bool> {
        Binding(get: { model.selectedEvent != nil },
                set: { if !$0 { model.selectedSeq = nil } })
    }
    #endif
}

// MARK: - 날짜 바

struct TimelineDateBar: View {
    let dates: [TimelineDate]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(dates) { date in
                        chip(date)
                            .id(date.date)
                    }
                }
                .padding(.vertical, AppSpacing.xxs)
            }
            .onAppear { proxy.scrollTo(selected, anchor: .trailing) }
            .onChange(of: selected) { _, value in
                withAnimation { proxy.scrollTo(value, anchor: .center) }
            }
        }
    }

    private func chip(_ date: TimelineDate) -> some View {
        let isSelected = date.date == selected
        return Button {
            onSelect(date.date)
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(TimelineFormat.shortDate(date.date))
                    .font(AppFont.monoDigit.weight(.semibold))
                Text("\(date.count)")
                    .font(AppFont.captionSmall)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                if date.failCount > 0 {
                    Text("\(date.failCount)")
                        .font(AppFont.captionSmall.weight(.semibold))
                        .foregroundStyle(.red)
                }
                if date.incompleteCount > 0 {
                    Text("\(date.incompleteCount)")
                        .font(AppFont.captionSmall.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.1),
                        in: Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help("호출 \(date.count)건 · 실패 \(date.failCount) · 응답 미기록 \(date.incompleteCount)")
        .accessibilityLabel("\(date.date) 호출 \(date.count)건, 실패 \(date.failCount), 응답 미기록 \(date.incompleteCount)")
    }
}

// MARK: - 요약

struct TimelineSummary: View {
    let stats: TimelineStats
    let onFocusSlowest: (Int) -> Void

    var body: some View {
        #if os(macOS)
        HStack(spacing: AppSpacing.sm) { cells }
        #else
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) { cells }
        }
        #endif
    }

    @ViewBuilder
    private var cells: some View {
        cell("연계 호출", "\(stats.callCount)건")
        cell("실패", "\(stats.failCount)건", tint: stats.failCount > 0 ? .red : nil)
        cell("응답 미기록", "\(stats.incompleteCount)건", tint: stats.incompleteCount > 0 ? .orange : nil)
        cell("평균 응답", TimelineFormat.duration(stats.avgElapsedMs))
        if let slowest = stats.slowest {
            Button {
                onFocusSlowest(slowest.seq)
            } label: {
                cell("최대 응답", TimelineFormat.duration(stats.maxElapsedMs), tint: .accentColor)
            }
            .buttonStyle(.plain)
            .help("\(slowest.interfaceId ?? "") \(slowest.name ?? "") (클릭 시 이동)")
        } else {
            cell("최대 응답", "-")
        }
    }

    private func cell(_ label: String, _ value: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(label)
                .font(AppFont.captionSmall)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(tint ?? .primary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        #if os(macOS)
        .frame(maxWidth: .infinity, alignment: .leading)
        #endif
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.xs))
    }
}

// MARK: - 필터

struct TimelineFilterBar: View {
    @ObservedObject var model: UserLogTimelineModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("IF ID, 명칭, 요청/응답 내용 검색", text: $model.filter.query)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                if !model.filter.query.isEmpty {
                    Button {
                        model.filter.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("검색어 지우기")
                }
                Text("\(model.visibleCount)/\(model.data?.events.count ?? 0)")
                    .font(AppFont.monoDigit)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.sm))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(TimelineKind.filterable, id: \.self) { kind in
                        chip(kind.label, isOn: model.filter.kinds.contains(kind)) {
                            if model.filter.kinds.contains(kind) {
                                model.filter.kinds.remove(kind)
                            } else {
                                model.filter.kinds.insert(kind)
                            }
                        }
                    }
                    Divider().frame(height: 16)
                    chip("문제만", isOn: model.filter.problemsOnly, tint: .red) {
                        model.filter.problemsOnly.toggle()
                    }
                    chip("스레드별 묶기", isOn: model.groupByThread) {
                        model.groupByThread.toggle()
                    }
                    .help("같은 스레드에서 이어진 처리(API 진입 → 연계 호출)를 한 묶음으로 표시")
                }
                .padding(.vertical, AppSpacing.xxs)
            }
        }
    }

    private func chip(_ title: String, isOn: Bool, tint: Color = .accentColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(AppFont.captionSmall)
                Text(title)
                    .font(AppFont.caption)
            }
            .foregroundStyle(isOn ? tint : .secondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(isOn ? tint.opacity(0.12) : Color.secondary.opacity(0.06), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

#Preview {
    let model = UserLogTimelineModel { _ in
        UserLogTimeline(file: "UT00000109114.log", date: "2026-11-03",
                        dates: [TimelineDate(date: "2026-11-02", count: 12, failCount: 1, incompleteCount: 0),
                                TimelineDate(date: "2026-11-03", count: 3, failCount: 1, incompleteCount: 1)],
                        events: [
                            TimelineEvent(seq: 1, kind: .api, status: .info, start: "2026-11-03 09:00:00.100",
                                          startMs: 0, elapsedMs: 1200, interfaceId: "LoginController.login", name: "로그인"),
                            TimelineEvent(seq: 2, status: .fail, start: "2026-11-03 09:00:00.200", startMs: 100,
                                          elapsedMs: 850, interfaceId: "IF_UTC_MDS_001", name: "사용자 정보 조회",
                                          resultCode: "E001"),
                            TimelineEvent(seq: 3, kind: .midas, status: .incomplete, start: "2026-11-03 09:00:00.900",
                                          startMs: 800, interfaceId: "MDS_002", name: "MIDAS 연계"),
                        ])
    }
    model.load(UserLogTimelineRequest(number: UserLogNumber("109114")!, base: nil))
    return NavigationStack {
        UserLogTimelineView(model: model)
    }
}
