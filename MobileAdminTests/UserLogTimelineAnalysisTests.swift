//
//  UserLogTimelineAnalysisTests.swift
//  MobileAdminTests
//
//  인터페이스 흐름 분석 — 웹 frontend/test/userLogTimeline.test.ts 케이스 + 경계값
//

import Testing
import Foundation
@testable import MobileAdmin

struct UserLogTimelineAnalysisTests {

    /// 2025-07-02 15:00:00 UTC
    private let base: Int64 = 1_751_468_400_000

    // MARK: - 세션

    @Test func sessionsSplitOnIdleGaps() {
        let events = [
            TimelineEvent(startMs: base, elapsedMs: 100),
            TimelineEvent(status: .fail, startMs: base + 1000, elapsedMs: 2000),
            TimelineEvent(kind: .api, status: .info, startMs: base + 10 * 60_000),
            TimelineEvent(status: .incomplete, startMs: base + 10 * 60_000 + 500),
        ]
        let sessions = TimelineAnalysis.sessions(events)

        #expect(sessions.count == 2)
        #expect(sessions[0].events.count == 2)
        #expect(sessions[0].endMs == base + 3000)
        #expect(sessions[0].failCount == 1)
        #expect(sessions[0].maxElapsedMs == 2000)
        #expect(sessions[1].callCount == 1)
        #expect(sessions[1].incompleteCount == 1)
    }

    @Test func sessionGapBoundaryIsInclusive() {
        let gap = TimelineAnalysis.sessionGapMs
        let justUnder = TimelineAnalysis.sessions([
            TimelineEvent(startMs: base), TimelineEvent(startMs: base + gap - 1),
        ])
        let exact = TimelineAnalysis.sessions([
            TimelineEvent(startMs: base), TimelineEvent(startMs: base + gap),
        ])
        #expect(justUnder.count == 1)
        #expect(exact.count == 2)
        #expect(exact.map(\.id) == [1, 2])
    }

    // MARK: - 필터

    @Test func filterAppliesKindProblemAndQuery() {
        let events = [
            TimelineEvent(startMs: base, interfaceId: "IF_UTC_MDS_001", name: "로그인된 사용자 정보 조회"),
            TimelineEvent(status: .fail, startMs: base, interfaceId: "IF_UTC_MDS_002"),
            TimelineEvent(kind: .log, status: .info, startMs: base, message: "warn"),
        ]

        #expect(TimelineAnalysis.filter(events, by: .init(kinds: [.esb])).count == 2)
        #expect(TimelineAnalysis.filter(events, by: .init(kinds: [.esb, .log], problemsOnly: true)).count == 1)
        #expect(TimelineAnalysis.filter(events, by: .init(kinds: [.esb], query: "사용자 정보")).count == 1)
    }

    @Test func filterQueryIsCaseInsensitiveAndSearchesBodies() {
        let events = [
            TimelineEvent(seq: 1, startMs: base, response: #"{"RLT_MSG":"Timeout"}"#),
            TimelineEvent(seq: 2, startMs: base, request: "plain"),
            TimelineEvent(seq: 3, startMs: base),
        ]
        #expect(TimelineAnalysis.filter(events, by: .init(query: "timeout")).map(\.seq) == [1])
        #expect(TimelineAnalysis.filter(events, by: .init(query: "  PLAIN ")).map(\.seq) == [2])
        // 스레드명도 검색 대상
        #expect(TimelineAnalysis.filter(events, by: .init(query: "exec-1")).count == 3)
    }

    @Test func filterKeepsUnknownKindRegardlessOfKindSelection() {
        let events = [TimelineEvent(kind: .unknown, status: .unknown, startMs: base)]
        #expect(TimelineAnalysis.filter(events, by: .init(kinds: [])).count == 1)
        #expect(TimelineAnalysis.filter(events, by: .init(problemsOnly: true)).isEmpty)
    }

    // MARK: - 통계

    @Test func statsIgnoreNonCallEventsForLatency() {
        let stats = TimelineAnalysis.stats([
            TimelineEvent(startMs: base, elapsedMs: 100),
            TimelineEvent(startMs: base, elapsedMs: 300, interfaceId: "SLOW"),
            TimelineEvent(status: .incomplete, startMs: base),
            TimelineEvent(kind: .log, status: .fail, startMs: base),
        ])

        #expect(stats.callCount == 3)
        #expect(stats.failCount == 1)
        #expect(stats.incompleteCount == 1)
        #expect(stats.avgElapsedMs == 200)
        #expect(stats.slowest?.interfaceId == "SLOW")
        #expect(stats.maxElapsedMs == 300)
    }

    @Test func statsRoundAverageHalfUpAndHandleEmpty() {
        let stats = TimelineAnalysis.stats([
            TimelineEvent(startMs: base, elapsedMs: 1),
            TimelineEvent(startMs: base, elapsedMs: 2),
        ])
        #expect(stats.avgElapsedMs == 2)   // 1.5 → 2

        let empty = TimelineAnalysis.stats([])
        #expect(empty == TimelineStats())
        #expect(empty.slowest == nil)
    }

    @Test func statsApiElapsedIsNotLatency() {
        let stats = TimelineAnalysis.stats([
            TimelineEvent(kind: .api, status: .info, startMs: base, elapsedMs: 9000),
            TimelineEvent(kind: .midas, startMs: base, elapsedMs: 40),
        ])
        #expect(stats.callCount == 1)
        #expect(stats.maxElapsedMs == 40)
    }

    // MARK: - 요청 묶음

    @Test func requestGroupsBundleInterleavedEventsPerThread() {
        func t(_ thread: String, _ offset: Int64, kind: TimelineKind = .esb,
               status: TimelineStatus = .ok, elapsed: Int64? = nil) -> TimelineEvent {
            TimelineEvent(seq: Int(offset), kind: kind, status: status, startMs: base + offset,
                          elapsedMs: elapsed, thread: thread)
        }
        let events = [
            t("A", 0, kind: .api, status: .info, elapsed: 5000),
            t("A", 100, elapsed: 200),
            t("B", 150, elapsed: 50),
            t("A", 3000, status: .fail, elapsed: 100), // API 소요 구간 안이므로 같은 묶음
            t("B", 4000, elapsed: 50),                 // 직전 종료 후 1.5s 초과 → 새 묶음
            t("A", 5200, kind: .api, status: .info),   // 새 API 진입 → 새 묶음
        ]
        let groups = TimelineAnalysis.requestGroups(events)

        #expect(groups.map(\.thread) == ["A", "B", "B", "A"])
        #expect(groups.map(\.events.count) == [3, 1, 1, 1])
        #expect(groups[0].entry?.seq == 0)
        #expect(groups[0].callCount == 2)
        #expect(groups[0].failCount == 1)
        #expect(groups[0].endMs == base + 5000)
        #expect(groups[0].id == "A-0")
        #expect(groups[1].entry == nil)
    }

    @Test func requestGroupGapBoundaryIsExclusive() {
        let gap = TimelineAnalysis.requestGapMs
        let exact = TimelineAnalysis.requestGroups([
            TimelineEvent(seq: 1, startMs: base), TimelineEvent(seq: 2, startMs: base + gap),
        ])
        let over = TimelineAnalysis.requestGroups([
            TimelineEvent(seq: 1, startMs: base), TimelineEvent(seq: 2, startMs: base + gap + 1),
        ])
        #expect(exact.count == 1)
        #expect(over.count == 2)
    }

    @Test func requestGroupEntryIsFirstApiEvenIfNotFirstEvent() {
        let groups = TimelineAnalysis.requestGroups([
            TimelineEvent(seq: 1, startMs: base),
            TimelineEvent(seq: 2, kind: .api, status: .info, startMs: base + 10),
        ])
        #expect(groups.count == 1)
        #expect(groups[0].entry?.seq == 2)
    }

    @Test func sectionsFilterThenGroup() {
        let events = [
            TimelineEvent(seq: 1, kind: .api, status: .info, startMs: base),
            TimelineEvent(seq: 2, status: .fail, startMs: base + 100),
            TimelineEvent(seq: 3, startMs: base + 20 * 60_000),
        ]
        let grouped = TimelineAnalysis.sections(events, filter: TimelineFilter(), groupByThread: true)
        #expect(grouped.count == 2)
        #expect(grouped[0].groups?.count == 1)

        let flat = TimelineAnalysis.sections(events, filter: TimelineFilter(problemsOnly: true), groupByThread: false)
        #expect(flat.count == 1)
        #expect(flat[0].groups == nil)
        #expect(flat[0].session.events.map(\.seq) == [2])
    }

    // MARK: - 포맷

    @Test func formatDuration() {
        #expect(TimelineFormat.duration(97) == "97ms")
        #expect(TimelineFormat.duration(999) == "999ms")
        #expect(TimelineFormat.duration(1000) == "1.00s")
        #expect(TimelineFormat.duration(2749) == "2.75s")
        #expect(TimelineFormat.duration(9999) == "10.00s")
        #expect(TimelineFormat.duration(12_500) == "12.5s")
        #expect(TimelineFormat.duration(129_000) == "2분 9초")
        #expect(TimelineFormat.duration(180_000) == "3분")
        #expect(TimelineFormat.duration(3_720_000) == "1시간 2분")
        #expect(TimelineFormat.duration(nil) == "-")
    }

    @Test func formatThreadAndTime() {
        #expect(TimelineFormat.shortThread("http-nio-58080-exec-24") == "exec-24")
        #expect(TimelineFormat.shortThread("tomcat-handler-346151") == "handler-346151")
        #expect(TimelineFormat.shortThread("main") == "main")
        #expect(TimelineFormat.timeOfDay("2026-11-03 09:00:00.123") == "09:00:00.123")
        #expect(TimelineFormat.timeOfDay(nil) == "")
        #expect(TimelineFormat.shortDate("2026-11-03") == "11-03")
        // startMs는 UTC로 간주한 값 — 기기 시간대와 무관하게 로그 시각 그대로
        #expect(TimelineFormat.clock(base) == "15:00:00")
    }

    @Test func prettyBodyKeepsKeyOrder() {
        #expect(TimelineFormat.prettyBody(#"{"a":1}"#) == "{\n  \"a\": 1\n}")
        #expect(TimelineFormat.prettyBody("{\"RDT\":\"1\"\n,\"SEQ\":\"1\"}") == "{\n  \"RDT\": \"1\",\n  \"SEQ\": \"1\"\n}")
        #expect(TimelineFormat.prettyBody("not json") == "not json")
        #expect(TimelineFormat.prettyBody(nil) == "")
    }

    @Test func prettyBodyHandlesNestingStringsAndBrokenJSON() {
        #expect(TimelineFormat.prettyBody(#"{"z":[1,{"b":{}}],"s":"a,b:{c}"}"#)
                == "{\n  \"z\": [\n    1,\n    {\n      \"b\": {}\n    }\n  ],\n  \"s\": \"a,b:{c}\"\n}")
        #expect(TimelineFormat.prettyBody(#"{"q":"say \"hi\", ok"}"#) == "{\n  \"q\": \"say \\\"hi\\\", ok\"\n}")
        #expect(TimelineFormat.prettyBody("[]") == "[]")
        // 깨진 JSON(서버가 2만 자에서 자른 본문 등)은 원문 그대로
        #expect(TimelineFormat.prettyBody(#"  {"a":1,"b"  "#) == #"{"a":1,"b""#)
    }
}
