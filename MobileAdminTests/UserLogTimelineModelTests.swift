//
//  UserLogTimelineModelTests.swift
//  MobileAdminTests
//
//  인터페이스 흐름 화면 상태 — 조회, 늦은 응답, 날짜 변경, 필터 재계산, 이동
//

import Testing
import Foundation
@testable import MobileAdmin

@MainActor
struct UserLogTimelineModelTests {

    private let number = UserLogNumber("109114")!

    /// 조건이 참이 될 때까지 대기 (최대 2초)
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private func makeDefaults() -> UserDefaults {
        let name = "UserLogTimelineModelTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func timeline(date: String, events: [TimelineEvent]) -> UserLogTimeline {
        UserLogTimeline(file: "UT00000109114.log",
                        date: date,
                        dates: [TimelineDate(date: "2026-11-02", count: 1, failCount: 0, incompleteCount: 0),
                                TimelineDate(date: date, count: events.count, failCount: 0, incompleteCount: 0)],
                        events: events)
    }

    private let sampleEvents: [TimelineEvent] = [
        TimelineEvent(seq: 1, kind: .api, status: .info, startMs: 0, thread: "A"),
        TimelineEvent(seq: 2, status: .fail, startMs: 100, elapsedMs: 300, thread: "A", interfaceId: "IF_SLOW"),
        TimelineEvent(seq: 3, startMs: 200, elapsedMs: 50, thread: "B", interfaceId: "IF_FAST"),
    ]

    @Test func loadsAndBuildsSections() async {
        var requested: [UserLogTimelineRequest] = []
        let events = sampleEvents
        let model = UserLogTimelineModel(defaults: makeDefaults()) { request in
            requested.append(request)
            return self.timeline(date: "2026-11-03", events: events)
        }
        model.load(UserLogTimelineRequest(number: number, base: .gcgfUntact))
        #expect(model.phase == .loading)
        await waitUntil { model.phase == .loaded }

        #expect(model.data?.date == "2026-11-03")
        #expect(model.stats.callCount == 2)
        #expect(model.stats.slowest?.seq == 2)
        #expect(model.visibleCount == 3)
        #expect(model.sections.count == 1)
        #expect(model.sections[0].groups?.map(\.thread) == ["A", "B"])
        #expect(requested.first?.date == nil)
        #expect(requested.first?.base == .gcgfUntact)
    }

    @Test func failureSetsErrorAndRetryClearsIt() async {
        var shouldFail = true
        let events = sampleEvents
        let model = UserLogTimelineModel(defaults: makeDefaults()) { _ in
            if shouldFail { throw NetworkError.server(statusCode: 404, message: "Log file not found", url: "") }
            return self.timeline(date: "2026-11-03", events: events)
        }
        model.load(UserLogTimelineRequest(number: number, base: nil))
        await waitUntil { model.phase == .failed }
        #expect(model.error != nil)
        #expect(model.data == nil)

        shouldFail = false
        model.reload()
        #expect(model.error == nil)
        await waitUntil { model.phase == .loaded }
        #expect(model.data != nil)
    }

    @Test func discardsLateResponseFromPreviousRequest() async {
        let events = sampleEvents
        let model = UserLogTimelineModel(defaults: makeDefaults()) { request in
            if request.number.value == 1 {
                try? await Task.sleep(for: .milliseconds(200))   // 먼저 보냈지만 늦게 도착
                return self.timeline(date: "2026-01-01", events: [])
            }
            return self.timeline(date: "2026-11-03", events: events)
        }
        model.load(UserLogTimelineRequest(number: UserLogNumber("1")!, base: nil))
        model.load(UserLogTimelineRequest(number: number, base: nil))
        await waitUntil { model.phase == .loaded }
        try? await Task.sleep(for: .milliseconds(300))

        #expect(model.data?.date == "2026-11-03")
        #expect(model.request?.number == number)
    }

    @Test func dateChangeKeepsPreviousResultWhileLoading() async {
        var requestedDates: [String?] = []
        var release: CheckedContinuation<Void, Never>?
        let events = sampleEvents
        let model = UserLogTimelineModel(defaults: makeDefaults()) { request in
            requestedDates.append(request.date)
            if request.date != nil {
                await withCheckedContinuation { release = $0 }
            }
            return self.timeline(date: request.date ?? "2026-11-03", events: events)
        }
        model.load(UserLogTimelineRequest(number: number, base: nil))
        await waitUntil { model.phase == .loaded }
        model.selectedSeq = 2

        model.select(date: "2026-11-02")
        await waitUntil { release != nil }
        #expect(model.isRefreshing)
        #expect(model.data?.date == "2026-11-03")
        #expect(model.selectedSeq == nil)

        release?.resume()
        await waitUntil { model.data?.date == "2026-11-02" }
        #expect(model.phase == .loaded)
        #expect(requestedDates == [nil, "2026-11-02"])
    }

    @Test func filterRecomputesSectionsButNotStats() async {
        let events = sampleEvents
        let model = UserLogTimelineModel(debounceInterval: .milliseconds(10), defaults: makeDefaults()) { _ in
            self.timeline(date: "2026-11-03", events: events)
        }
        model.load(UserLogTimelineRequest(number: number, base: nil))
        await waitUntil { model.phase == .loaded }

        model.filter.problemsOnly = true
        await waitUntil { model.visibleCount == 1 }
        #expect(model.visibleCount == 1)
        #expect(model.stats.callCount == 2)

        model.filter.problemsOnly = false
        model.filter.query = "if_fast"
        await waitUntil { model.visibleCount == 1 && model.sections.first?.session.events.first?.seq == 3 }
        #expect(model.sections.first?.session.events.map(\.seq) == [3])
    }

    @Test func groupByThreadIsPersisted() async {
        let defaults = makeDefaults()
        let events = sampleEvents
        let model = UserLogTimelineModel(defaults: defaults) { _ in self.timeline(date: "2026-11-03", events: events) }
        #expect(model.groupByThread)
        model.load(UserLogTimelineRequest(number: number, base: nil))
        await waitUntil { model.phase == .loaded }

        model.groupByThread = false
        await waitUntil { model.sections.first?.groups == nil }
        #expect(model.sections.first?.groups == nil)
        #expect(defaults.bool(forKey: UserLogTimelineModel.groupByThreadKey) == false)
        #expect(UserLogTimelineModel(defaults: defaults).groupByThread == false)
    }

    @Test func focusExpandsCollapsedGroupAndRequestsScroll() async throws {
        let events = sampleEvents
        let model = UserLogTimelineModel(defaults: makeDefaults()) { _ in self.timeline(date: "2026-11-03", events: events) }
        model.load(UserLogTimelineRequest(number: number, base: nil))
        await waitUntil { model.phase == .loaded }

        let groupID = try #require(model.sections.first?.groups?.first?.id)
        model.toggleGroup(groupID)
        #expect(model.collapsedGroups.contains(groupID))

        model.focus(seq: 2)
        #expect(model.selectedSeq == 2)
        #expect(model.selectedEvent?.interfaceId == "IF_SLOW")
        #expect(!model.collapsedGroups.contains(groupID))
        #expect(model.scrollRequest?.seq == 2)
    }

    @Test func focusOnFilteredOutEventResetsFilter() async {
        let events = sampleEvents
        let model = UserLogTimelineModel(debounceInterval: .milliseconds(10), defaults: makeDefaults()) { _ in
            self.timeline(date: "2026-11-03", events: events)
        }
        model.load(UserLogTimelineRequest(number: number, base: nil))
        await waitUntil { model.phase == .loaded }
        model.filter.kinds = [.api]
        await waitUntil { model.visibleCount == 1 }

        model.focus(seq: 3)
        await waitUntil { model.scrollRequest?.seq == 3 }
        #expect(model.filter.isDefault)
        #expect(model.visibleCount == 3)
        #expect(model.scrollRequest?.seq == 3)
    }
}
