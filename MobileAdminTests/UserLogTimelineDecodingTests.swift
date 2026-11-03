//
//  UserLogTimelineDecodingTests.swift
//  MobileAdminTests
//
//  인터페이스 흐름 응답(/admin/getUserLogTimeline/:no) 디코딩
//

import Testing
import Foundation
@testable import MobileAdmin

struct UserLogTimelineDecodingTests {

    private func decode(_ json: String) throws -> UserLogTimeline {
        try JSONDecoder().decode(UserLogTimeline.self, from: Data(json.utf8))
    }

    @Test func decodesFullResponse() throws {
        let timeline = try decode("""
        {
          "file": "UT00000109114.log",
          "date": "2026-11-03",
          "dates": [
            {"date": "2026-11-02", "count": 41, "failCount": 2, "incompleteCount": 1},
            {"date": "2026-11-03", "count": 3, "failCount": 1, "incompleteCount": 0}
          ],
          "events": [
            {"seq": 1, "kind": "api", "status": "info", "start": "2026-11-03 09:00:00.100",
             "startMs": 1793696400100, "end": "2026-11-03 09:00:01.300", "elapsedMs": 1200,
             "thread": "http-nio-58080-exec-24", "source": "LoggingAspect",
             "interfaceId": "LoginController.login", "name": "로그인"},
            {"seq": 2, "kind": "esb", "status": "fail", "start": "2026-11-03 09:00:00.200",
             "startMs": 1793696400200, "elapsedMs": 850, "thread": "http-nio-58080-exec-24",
             "source": "EsbInterfaceV2", "interfaceId": "IF_UTC_MDS_001", "name": "사용자 정보 조회",
             "httpStatus": "200", "resultCode": "E001", "resultMsg": "오류",
             "request": "{\\"a\\":1}", "response": "{\\"RLT_CODE\\":\\"E001\\"}"},
            {"seq": 3, "kind": "log", "status": "fail", "start": "2026-11-03 09:00:02.000",
             "startMs": 1793696402000, "thread": "http-nio-58080-exec-24", "level": "ERROR",
             "name": "EsbServiceImpl", "message": "NullPointerException"}
          ],
          "truncated": false
        }
        """)

        #expect(timeline.file == "UT00000109114.log")
        #expect(timeline.date == "2026-11-03")
        #expect(timeline.dates.map(\.date) == ["2026-11-02", "2026-11-03"])
        #expect(timeline.dates[0].failCount == 2)
        #expect(timeline.events.count == 3)
        #expect(!timeline.truncated)
        #expect(!timeline.isEmpty)

        let esb = timeline.events[1]
        #expect(esb.kind == .esb)
        #expect(esb.status == .fail)
        #expect(esb.elapsedMs == 850)
        #expect(esb.resultCode == "E001")
        #expect(esb.request == "{\"a\":1}")
        #expect(esb.end == nil)

        let log = timeline.events[2]
        #expect(log.kind == .log)
        #expect(log.level == "ERROR")
        #expect(log.elapsedMs == nil)
    }

    @Test func decodesRequiredFieldsOnly() throws {
        let timeline = try decode("""
        {"file": "a.log", "date": "2026-11-03", "dates": [], "truncated": true,
         "events": [{"seq": 7, "kind": "midas", "status": "incomplete",
                     "start": "2026-11-03 10:00:00.000", "startMs": 1, "thread": "unknown"}]}
        """)
        let event = try #require(timeline.events.first)
        #expect(event.seq == 7)
        #expect(event.kind == .midas)
        #expect(event.status == .incomplete)
        #expect(event.interfaceId == nil)
        #expect(event.request == nil)
        #expect(timeline.truncated)
    }

    @Test func unknownKindAndStatusDecodeAsUnknown() throws {
        let timeline = try decode("""
        {"file": "a.log", "date": "d", "dates": [], "truncated": false,
         "events": [{"seq": 1, "kind": "kafka", "status": "retry",
                     "start": "s", "startMs": 0, "thread": "t"}]}
        """)
        #expect(timeline.events[0].kind == .unknown)
        #expect(timeline.events[0].status == .unknown)
    }

    @Test func nullOrMissingArraysBecomeEmpty() throws {
        let nulls = try decode(#"{"file": "a.log", "date": "", "dates": null, "events": null, "truncated": false}"#)
        #expect(nulls.dates.isEmpty)
        #expect(nulls.events.isEmpty)

        let missing = try decode(#"{"file": "a.log", "date": ""}"#)
        #expect(missing.dates.isEmpty)
        #expect(missing.events.isEmpty)
        #expect(!missing.truncated)
    }

    @Test func emptyResultIsEmpty() throws {
        let timeline = try decode(#"{"file": "UT00000000001.log", "date": "", "dates": [], "events": [], "truncated": false}"#)
        #expect(timeline.isEmpty)
        #expect(timeline.date.isEmpty)
    }

    @Test func logDateFromErrorRegisterDt() {
        #expect(UserLogTimelineRequest.logDate(fromRegisterDt: "2026-11-03T09:12:33.123456") == "2026-11-03")
        #expect(UserLogTimelineRequest.logDate(fromRegisterDt: "2024-10-01") == "2024-10-01")
        #expect(UserLogTimelineRequest.logDate(fromRegisterDt: "20261103") == "2026-11-03")
        #expect(UserLogTimelineRequest.logDate(fromRegisterDt: "") == nil)
        #expect(UserLogTimelineRequest.logDate(fromRegisterDt: nil) == nil)
        #expect(UserLogTimelineRequest.logDate(fromRegisterDt: "N/A") == nil)
    }

    @Test func eventsCompareBySeqOnly() {
        let a = TimelineEvent(seq: 1, startMs: 0, request: "a")
        let b = TimelineEvent(seq: 1, startMs: 99, request: "b")
        #expect(a == b)
        #expect(Set([a, b]).count == 1)
    }
}
