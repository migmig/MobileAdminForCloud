//
//  UserLogTimelineAnalysis.swift
//  MobileAdmin
//
//  인터페이스 흐름 분석 — 세션/요청 묶기, 필터, 통계, 표시 포맷
//  웹(admin_golang frontend/src/utils/userLogTimeline.ts)과 결과가 같도록 그대로 옮긴 순수 함수
//

import Foundation

// MARK: - 이벤트 보조 속성

extension TimelineEvent {
    /// 연계 호출(ESB/MIDAS) 여부
    var isCall: Bool { kind == .esb || kind == .midas }

    var endMs: Int64 { startMs + (elapsedMs ?? 0) }

    /// 실패 또는 응답 미기록
    var isProblem: Bool { status == .fail || status == .incomplete }

    /// 목록 제목 — 명칭이 없으면 IF ID, 그것도 없으면 소스
    var displayTitle: String {
        name ?? interfaceId ?? source ?? kind.label
    }
}

// MARK: - 묶음 / 통계 타입

struct TimelineFilter: Equatable, Sendable {
    var kinds: Set<TimelineKind> = Set(TimelineKind.filterable)
    var problemsOnly = false
    var query = ""

    var isDefault: Bool { self == TimelineFilter() }
}

/// 사용자 접속 구간 — 이벤트 사이 공백이 길면 나눈다
struct TimelineSession: Identifiable, Sendable {
    let id: Int
    var startMs: Int64
    var endMs: Int64
    var events: [TimelineEvent] = []
    var callCount = 0
    var failCount = 0
    var incompleteCount = 0
    var maxElapsedMs: Int64 = 0
}

/// 같은 스레드에서 이어진 처리(API 진입 → 연계 호출) 묶음
struct TimelineRequestGroup: Identifiable, Sendable {
    /// "\(thread)-\(첫 이벤트 seq)"
    let id: String
    let thread: String
    var events: [TimelineEvent] = []
    /// 묶음의 대표 API 진입 이벤트
    var entry: TimelineEvent?
    var startMs: Int64
    var endMs: Int64
    var callCount = 0
    var failCount = 0
    var incompleteCount = 0
}

struct TimelineStats: Equatable, Sendable {
    var callCount = 0
    /// ERROR 로그 포함
    var failCount = 0
    /// 연계 호출만
    var incompleteCount = 0
    var avgElapsedMs: Int64 = 0
    var maxElapsedMs: Int64 = 0
    var slowest: TimelineEvent?
}

/// 화면 목록 단위 — 세션 하나와 (스레드별 묶기가 켜져 있으면) 그 안의 요청 묶음
struct TimelineSection: Identifiable, Sendable {
    let session: TimelineSession
    let groups: [TimelineRequestGroup]?

    var id: Int { session.id }
}

// MARK: - 분석

enum TimelineAnalysis {
    /// 이 이상 비면 별도 세션
    static let sessionGapMs: Int64 = 5 * 60 * 1000
    /// 같은 스레드에서 직전 종료 후 이 시간을 넘게 비면 새 요청 묶음 (스레드 풀 재사용 고려)
    static let requestGapMs: Int64 = 1500

    /// 이벤트 사이 공백이 gapMs 이상이면 별도 세션(사용자 접속 구간)으로 분리한다.
    static func sessions(_ events: [TimelineEvent], gapMs: Int64 = sessionGapMs) -> [TimelineSession] {
        var sessions: [TimelineSession] = []

        for ev in events {
            if sessions.isEmpty || ev.startMs - sessions[sessions.count - 1].endMs >= gapMs {
                sessions.append(TimelineSession(id: sessions.count + 1, startMs: ev.startMs, endMs: ev.endMs))
            }
            let i = sessions.count - 1
            sessions[i].events.append(ev)
            sessions[i].endMs = max(sessions[i].endMs, ev.endMs)
            if ev.isCall {
                sessions[i].callCount += 1
                sessions[i].maxElapsedMs = max(sessions[i].maxElapsedMs, ev.elapsedMs ?? 0)
            }
            if ev.status == .fail { sessions[i].failCount += 1 }
            if ev.status == .incomplete { sessions[i].incompleteCount += 1 }
        }
        return sessions
    }

    /// 같은 스레드에서 이어지는 이벤트를 하나의 요청 묶음으로 만든다.
    /// 스레드는 풀에서 재사용되므로 API 진입 이벤트가 오거나, 직전 이벤트 종료 후 gapMs를 넘게 비면 새 묶음으로 나눈다.
    static func requestGroups(_ events: [TimelineEvent], gapMs: Int64 = requestGapMs) -> [TimelineRequestGroup] {
        var groups: [TimelineRequestGroup] = []
        var open: [String: Int] = [:]   // thread -> groups 인덱스

        for ev in events {
            let startsNew: Bool
            if let i = open[ev.thread] {
                let group = groups[i]
                startsNew = ev.startMs - group.endMs > gapMs
                    || (ev.kind == .api && group.events.contains { $0.kind == .api })
            } else {
                startsNew = true
            }
            if startsNew {
                groups.append(TimelineRequestGroup(id: "\(ev.thread)-\(ev.seq)",
                                                   thread: ev.thread,
                                                   entry: ev.kind == .api ? ev : nil,
                                                   startMs: ev.startMs,
                                                   endMs: ev.endMs))
                open[ev.thread] = groups.count - 1
            }
            let i = open[ev.thread]!
            groups[i].events.append(ev)
            groups[i].endMs = max(groups[i].endMs, ev.endMs)
            if groups[i].entry == nil && ev.kind == .api { groups[i].entry = ev }
            if ev.isCall { groups[i].callCount += 1 }
            if ev.status == .fail { groups[i].failCount += 1 }
            if ev.status == .incomplete { groups[i].incompleteCount += 1 }
        }
        return groups
    }

    /// 종류 · 문제만 · 검색어 필터. 모르는 종류(.unknown)는 종류 필터와 무관하게 표시한다.
    static func filter(_ events: [TimelineEvent], by filter: TimelineFilter) -> [TimelineEvent] {
        let query = filter.query.trimmingCharacters(in: .whitespacesAndNewlines)
        return events.filter { ev in
            if ev.kind != .unknown && !filter.kinds.contains(ev.kind) { return false }
            if filter.problemsOnly && !ev.isProblem { return false }
            if query.isEmpty { return true }
            return [ev.interfaceId, ev.name, ev.thread, ev.resultCode, ev.resultMsg, ev.message, ev.request, ev.response]
                .contains { $0?.range(of: query, options: .caseInsensitive) != nil }
        }
    }

    static func stats(_ events: [TimelineEvent]) -> TimelineStats {
        var stats = TimelineStats()
        var total: Int64 = 0
        var measured: Int64 = 0

        for ev in events {
            if ev.status == .fail { stats.failCount += 1 }
            guard ev.isCall else { continue }
            stats.callCount += 1
            if ev.status == .incomplete { stats.incompleteCount += 1 }
            if let elapsed = ev.elapsedMs {
                total += elapsed
                measured += 1
                if stats.slowest == nil || elapsed > (stats.slowest?.elapsedMs ?? 0) {
                    stats.slowest = ev
                }
            }
        }
        // Math.round과 같게 0.5는 올림
        stats.avgElapsedMs = measured > 0 ? Int64((Double(total) / Double(measured)).rounded(.toNearestOrAwayFromZero)) : 0
        stats.maxElapsedMs = stats.slowest?.elapsedMs ?? 0
        return stats
    }

    /// 화면 목록 구성: 필터 → 세션 → (선택) 스레드별 요청 묶음
    static func sections(_ events: [TimelineEvent], filter: TimelineFilter, groupByThread: Bool) -> [TimelineSection] {
        sessions(Self.filter(events, by: filter)).map { session in
            TimelineSection(session: session, groups: groupByThread ? requestGroups(session.events) : nil)
        }
    }
}

// MARK: - 표시 포맷

enum TimelineFormat {
    /// 97ms · 2.75s · 12.5s · 2분 9초 · 3분 · 1시간 2분 · nil이면 -
    static func duration(_ ms: Int64?) -> String {
        guard let ms else { return "-" }
        if ms < 1000 { return "\(ms)ms" }
        if ms < 60_000 {
            return String(format: ms < 10_000 ? "%.2fs" : "%.1fs", Double(ms) / 1000)
        }
        let totalSec = Int64((Double(ms) / 1000).rounded(.toNearestOrAwayFromZero))
        let h = totalSec / 3600
        let m = (totalSec % 3600) / 60
        let s = totalSec % 60
        if h > 0 { return "\(h)시간 \(m)분" }
        return s > 0 ? "\(m)분 \(s)초" : "\(m)분"
    }

    /// 'YYYY-MM-DD HH:mm:ss.SSS' → 'HH:mm:ss.SSS'
    static func timeOfDay(_ timestamp: String?) -> String {
        guard let timestamp, timestamp.count > 11 else { return "" }
        return String(timestamp.dropFirst(11))
    }

    /// http-nio-58080-exec-24 → exec-24, tomcat-handler-346151 → handler-346151
    static func shortThread(_ thread: String) -> String {
        guard let match = thread.firstMatch(of: #/([A-Za-z]+-\d+)$/#) else { return thread }
        return String(match.1)
    }

    /// 'YYYY-MM-DD' → 'MM-DD'
    static func shortDate(_ date: String) -> String {
        date.count == 10 ? String(date.dropFirst(5)) : date
    }

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // startMs는 현지 시각을 UTC로 간주한 값이라 UTC로 포맷해야 로그 시각과 같다
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// startMs 계열 값 → 'HH:mm:ss' (로그에 적힌 시각)
    static func clock(_ ms: Int64) -> String {
        clockFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(ms) / 1000))
    }

    /// JSON이면 들여쓰기 정렬(키 순서 유지), 아니면 원문 그대로
    static func prettyBody(_ text: String?) -> String {
        guard let text else { return "" }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first == "{" || first == "[",
              let data = trimmed.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            return trimmed
        }
        return reindentJSON(trimmed)
    }

    /// 유효한 JSON 문자열을 2칸 들여쓰기로 다시 배치한다. 키 순서와 값 표기는 원문 그대로 둔다.
    private static func reindentJSON(_ json: String) -> String {
        let scalars = Array(json.unicodeScalars)
        var out = String.UnicodeScalarView()
        var depth = 0
        var inString = false
        var escaped = false

        func newline() {
            out.append("\n")
            out.append(contentsOf: String(repeating: "  ", count: depth).unicodeScalars)
        }
        func nextSignificant(after index: Int) -> Unicode.Scalar? {
            var j = index + 1
            while j < scalars.count, scalars[j].properties.isWhitespace { j += 1 }
            return j < scalars.count ? scalars[j] : nil
        }

        var i = 0
        while i < scalars.count {
            let c = scalars[i]
            if inString {
                out.append(c)
                if escaped {
                    escaped = false
                } else if c == "\\" {
                    escaped = true
                } else if c == "\"" {
                    inString = false
                }
                i += 1
                continue
            }
            switch c {
            case "\"":
                inString = true
                out.append(c)
            case "{", "[":
                let close: Unicode.Scalar = c == "{" ? "}" : "]"
                if nextSignificant(after: i) == close {
                    // 빈 객체/배열은 한 줄로
                    out.append(c)
                    out.append(close)
                    while i + 1 < scalars.count, scalars[i + 1] != close { i += 1 }
                    i += 1
                } else {
                    out.append(c)
                    depth += 1
                    newline()
                }
            case "}", "]":
                depth -= 1
                newline()
                out.append(c)
            case ",":
                out.append(c)
                newline()
            case ":":
                out.append(contentsOf: ": ".unicodeScalars)
            default:
                if !c.properties.isWhitespace { out.append(c) }
            }
            i += 1
        }
        return String(out)
    }
}
