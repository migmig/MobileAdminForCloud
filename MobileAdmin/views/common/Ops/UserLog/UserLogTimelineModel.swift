//
//  UserLogTimelineModel.swift
//  MobileAdmin
//
//  사용자 로그 인터페이스 흐름 화면 상태
//  조회(서버 파싱) → 통계(필터 전 전체) → 필터·세션·요청 묶음(백그라운드 계산) → sections
//

import Foundation

@MainActor
final class UserLogTimelineModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    typealias Fetcher = (UserLogTimelineRequest) async throws -> UserLogTimeline

    static let groupByThreadKey = "userLog.timeline.groupByThread"

    @Published private(set) var request: UserLogTimelineRequest?
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var error: Error?
    /// 날짜 변경·다시 불러오기 중에도 이전 결과를 유지한다
    @Published private(set) var data: UserLogTimeline?
    /// 필터 전 전체 이벤트 기준
    @Published private(set) var stats = TimelineStats()
    @Published private(set) var sections: [TimelineSection] = []
    @Published private(set) var visibleCount = 0
    @Published var filter = TimelineFilter() {
        didSet {
            guard filter != oldValue else { return }
            recompute(debounce: filter.query != oldValue.query)
        }
    }
    @Published var groupByThread: Bool {
        didSet {
            guard groupByThread != oldValue else { return }
            defaults.set(groupByThread, forKey: Self.groupByThreadKey)
            recompute(debounce: false)
        }
    }
    @Published var selectedSeq: Int?
    @Published private(set) var collapsedGroups: Set<String> = []
    /// 목록 스크롤 요청 (같은 이벤트로 다시 이동해도 값이 바뀌도록 nonce 포함)
    @Published private(set) var scrollRequest: ScrollRequest?

    struct ScrollRequest: Equatable {
        let seq: Int
        let nonce: Int
    }

    private let fetcher: Fetcher
    private let debounceInterval: Duration
    private let defaults: UserDefaults
    private var loadTask: Task<Void, Never>?
    private var recomputeTask: Task<Void, Never>?
    /// 늦게 도착한 이전 요청 결과를 버리기 위한 세대 번호
    private var generation = 0
    private var scrollNonce = 0
    /// 필터에 가려진 이벤트로 이동할 때, 재계산이 끝난 뒤 스크롤하기 위해 보관
    private var pendingFocusSeq: Int?

    init(debounceInterval: Duration = .milliseconds(300),
         defaults: UserDefaults = .standard,
         fetcher: @escaping Fetcher = { request in
             try await OpsServices.userLog.fetchTimeline(number: request.number,
                                                         base: request.base,
                                                         date: request.date)
         }) {
        self.debounceInterval = debounceInterval
        self.defaults = defaults
        self.fetcher = fetcher
        groupByThread = defaults.object(forKey: Self.groupByThreadKey) as? Bool ?? true
    }

    var isLoading: Bool { phase == .loading }

    /// 결과가 있는 상태에서 다시 불러오는 중
    var isRefreshing: Bool { phase == .loading && data != nil }

    var selectedEvent: TimelineEvent? {
        guard let selectedSeq else { return nil }
        return data?.events.first { $0.seq == selectedSeq }
    }

    // MARK: - 조회

    /// 새 대상 분석 — 이전 결과, 선택, 접힘을 지운다 (필터는 유지)
    func load(_ request: UserLogTimelineRequest) {
        data = nil
        stats = TimelineStats()
        sections = []
        visibleCount = 0
        resetSelection()
        fetch(request)
    }

    /// 같은 대상의 다른 날짜
    func select(date: String) {
        guard let request, date != data?.date else { return }
        resetSelection()
        fetch(UserLogTimelineRequest(number: request.number, base: request.base, date: date))
    }

    /// 현재 대상 + 현재 날짜 다시 불러오기
    func reload() {
        guard let request else { return }
        let date = data?.date.isEmpty == false ? data?.date : request.date
        fetch(UserLogTimelineRequest(number: request.number, base: request.base, date: date))
    }

    func cancel() {
        generation += 1
        loadTask?.cancel()
        loadTask = nil
        if phase == .loading {
            phase = data == nil ? .idle : .loaded
        }
    }

    /// 대상 닫기 — 처음 상태로
    func reset() {
        cancel()
        request = nil
        data = nil
        error = nil
        phase = .idle
        stats = TimelineStats()
        sections = []
        visibleCount = 0
        resetSelection()
    }

    private func fetch(_ request: UserLogTimelineRequest) {
        loadTask?.cancel()
        generation += 1
        let generation = self.generation
        self.request = request
        phase = .loading
        error = nil

        loadTask = Task { [weak self, fetcher] in
            do {
                let result = try await fetcher(request)
                guard let self, generation == self.generation else { return }
                let filter = self.filter
                let groupByThread = self.groupByThread
                let sections = await Task.detached(priority: .userInitiated) {
                    TimelineAnalysis.sections(result.events, filter: filter, groupByThread: groupByThread)
                }.value
                let stats = TimelineAnalysis.stats(result.events)
                guard generation == self.generation else { return }
                // 계산 중 필터가 바뀌었으면 아래 recompute가 다시 맞춘다
                self.data = result
                self.stats = stats
                self.apply(sections)
                self.phase = .loaded
                if filter != self.filter || groupByThread != self.groupByThread {
                    self.recompute(debounce: false)
                }
            } catch {
                guard let self, generation == self.generation, !OpsError.isCancellation(error) else { return }
                self.error = error
                self.phase = .failed
            }
        }
    }

    // MARK: - 필터 / 묶음 재계산

    func resetFilter() {
        filter = TimelineFilter()
    }

    private func recompute(debounce: Bool) {
        recomputeTask?.cancel()
        guard let events = data?.events else { return }
        let filter = self.filter
        let groupByThread = self.groupByThread
        let delay = debounceInterval

        recomputeTask = Task { [weak self] in
            if debounce {
                try? await Task.sleep(for: delay)
                if Task.isCancelled { return }
            }
            let sections = await Task.detached(priority: .userInitiated) {
                TimelineAnalysis.sections(events, filter: filter, groupByThread: groupByThread)
            }.value
            guard let self, !Task.isCancelled else { return }
            self.apply(sections)
        }
    }

    private func apply(_ sections: [TimelineSection]) {
        self.sections = sections
        visibleCount = sections.reduce(0) { $0 + $1.session.events.count }
        if let seq = pendingFocusSeq, isVisible(seq) {
            pendingFocusSeq = nil
            // 필터가 바뀌면 묶음 id도 바뀌므로 새 묶음 기준으로 다시 펼친다
            if let groupID = groupID(containing: seq) {
                collapsedGroups.remove(groupID)
            }
            requestScroll(to: seq)
        }
    }

    // MARK: - 선택 / 이동

    func toggleGroup(_ id: String) {
        if collapsedGroups.contains(id) {
            collapsedGroups.remove(id)
        } else {
            collapsedGroups.insert(id)
        }
    }

    /// 이벤트를 선택하고 목록에서 보이게 한다 — 접힌 묶음은 펼치고, 필터에 가려졌으면 필터를 초기화한다
    func focus(seq: Int) {
        selectedSeq = seq
        if let groupID = groupID(containing: seq) {
            collapsedGroups.remove(groupID)
        }
        if isVisible(seq) {
            requestScroll(to: seq)
        } else {
            pendingFocusSeq = seq
            resetFilter()
        }
    }

    private func requestScroll(to seq: Int) {
        scrollNonce += 1
        scrollRequest = ScrollRequest(seq: seq, nonce: scrollNonce)
    }

    private func isVisible(_ seq: Int) -> Bool {
        sections.contains { $0.session.events.contains { $0.seq == seq } }
    }

    private func groupID(containing seq: Int) -> String? {
        for section in sections {
            if let group = section.groups?.first(where: { $0.events.contains { $0.seq == seq } }) {
                return group.id
            }
        }
        return nil
    }

    private func resetSelection() {
        selectedSeq = nil
        collapsedGroups = []
        pendingFocusSeq = nil
        scrollRequest = nil
    }
}
