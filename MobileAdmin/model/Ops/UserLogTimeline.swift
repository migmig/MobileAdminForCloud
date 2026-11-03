//
//  UserLogTimeline.swift
//  MobileAdmin
//
//  사용자 로그 인터페이스 흐름 응답 모델 (/admin/getUserLogTimeline/:no)
//  로그 파싱은 서버가 하고, 앱은 결과 이벤트를 묶고 거르고 집계해서 보여준다.
//

import Foundation

// MARK: - 종류 / 상태

enum TimelineKind: String, CaseIterable, Hashable, Sendable {
    case esb, midas, api, log
    /// 서버에 새 종류가 생겨도 디코딩이 깨지지 않도록
    case unknown

    /// 필터에서 선택할 수 있는 종류
    static let filterable: [TimelineKind] = [.esb, .midas, .api, .log]

    var label: String {
        switch self {
        case .esb:     return "ESB"
        case .midas:   return "MIDAS"
        case .api:     return "API 진입"
        case .log:     return "WARN/ERROR"
        case .unknown: return "기타"
        }
    }
}

enum TimelineStatus: String, Hashable, Sendable {
    case ok, fail, incomplete, info
    case unknown
}

extension TimelineKind: Decodable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TimelineKind(rawValue: raw) ?? .unknown
    }
}

extension TimelineStatus: Decodable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TimelineStatus(rawValue: raw) ?? .unknown
    }
}

// MARK: - 이벤트

struct TimelineEvent: Decodable, Identifiable, Hashable, Sendable {
    /// 날짜 안에서 1부터 매긴 순번
    let seq: Int
    let kind: TimelineKind
    let status: TimelineStatus
    /// YYYY-MM-DD HH:mm:ss.SSS (로그에 적힌 서버 현지 시각)
    let start: String
    /// start를 UTC로 간주한 epoch ms — 정렬과 간격 계산에만 사용 (Date로 바꾸지 않는다)
    let startMs: Int64
    let end: String?
    let elapsedMs: Int64?
    let thread: String
    let source: String?
    let level: String?
    let interfaceId: String?
    let name: String?
    let httpStatus: String?
    let resultCode: String?
    let resultMsg: String?
    let header: String?
    let request: String?
    let response: String?
    let message: String?

    var id: Int { seq }

    init(seq: Int = 0,
         kind: TimelineKind = .esb,
         status: TimelineStatus = .ok,
         start: String = "",
         startMs: Int64,
         end: String? = nil,
         elapsedMs: Int64? = nil,
         thread: String = "http-nio-58080-exec-1",
         source: String? = nil,
         level: String? = nil,
         interfaceId: String? = nil,
         name: String? = nil,
         httpStatus: String? = nil,
         resultCode: String? = nil,
         resultMsg: String? = nil,
         header: String? = nil,
         request: String? = nil,
         response: String? = nil,
         message: String? = nil) {
        self.seq = seq
        self.kind = kind
        self.status = status
        self.start = start
        self.startMs = startMs
        self.end = end
        self.elapsedMs = elapsedMs
        self.thread = thread
        self.source = source
        self.level = level
        self.interfaceId = interfaceId
        self.name = name
        self.httpStatus = httpStatus
        self.resultCode = resultCode
        self.resultMsg = resultMsg
        self.header = header
        self.request = request
        self.response = response
        self.message = message
    }

    // 본문까지 비교하면 비용이 크므로 순번으로만 비교
    static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        lhs.seq == rhs.seq
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(seq)
    }
}

// MARK: - 날짜 요약 / 응답

struct TimelineDate: Decodable, Identifiable, Hashable, Sendable {
    let date: String
    /// log 종류를 뺀 이벤트 수
    let count: Int
    /// ERROR 로그 포함
    let failCount: Int
    let incompleteCount: Int

    var id: String { date }
}

struct UserLogTimeline: Decodable, Sendable {
    let file: String
    /// 실제로 선택된 날짜. 이벤트가 하나도 없으면 ""
    let date: String
    /// 로그에 있는 모든 날짜 (오래된 순)
    let dates: [TimelineDate]
    /// 선택된 날짜의 이벤트 (시작 시각 순)
    let events: [TimelineEvent]
    /// 하루 이벤트가 상한(3000)을 넘어 앞부분을 잘랐는지
    let truncated: Bool

    /// 서버가 하루에 돌려주는 최대 이벤트 수
    static let maxEventsPerDate = 3_000

    private enum CodingKeys: String, CodingKey {
        case file, date, dates, events, truncated
    }

    init(file: String = "", date: String = "", dates: [TimelineDate] = [],
         events: [TimelineEvent] = [], truncated: Bool = false) {
        self.file = file
        self.date = date
        self.dates = dates
        self.events = events
        self.truncated = truncated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        file = try container.decodeIfPresent(String.self, forKey: .file) ?? ""
        date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        dates = try container.decodeIfPresent([TimelineDate].self, forKey: .dates) ?? []
        events = try container.decodeIfPresent([TimelineEvent].self, forKey: .events) ?? []
        truncated = try container.decodeIfPresent(Bool.self, forKey: .truncated) ?? false
    }

    var isEmpty: Bool { dates.isEmpty }
}

/// 사용자 로그 화면 보기 — 마지막으로 쓴 보기를 @AppStorage(storageKey)로 기억한다
enum UserLogViewMode: String, CaseIterable, Identifiable {
    case timeline
    case stream

    static let storageKey = "userLog.viewMode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timeline: return "인터페이스 흐름"
        case .stream:   return "실시간 로그"
        }
    }
}

/// 흐름 분석 대상
struct UserLogTimelineRequest: Hashable {
    let number: UserLogNumber
    /// nil = 자동 (서버 기본 경로)
    let base: NasLogBase?
    /// nil = 가장 최근 날짜
    let date: String?
    /// 같은 대상을 다시 분석해도 값이 달라지도록
    let requestedAt: Date

    init(number: UserLogNumber, base: NasLogBase?, date: String? = nil, requestedAt: Date = Date()) {
        self.number = number
        self.base = base
        self.date = date
        self.requestedAt = requestedAt
    }

    /// 오류 등록일시(yyyy-MM-dd'T'HH:mm:ss… 또는 yyyyMMdd, 서버 현지 시각) → 로그 날짜 'YYYY-MM-DD'
    static func logDate(fromRegisterDt registerDt: String?) -> String? {
        guard let registerDt else { return nil }
        if let match = registerDt.prefixMatch(of: #/(\d{4})-(\d{2})-(\d{2})/#) {
            return "\(match.1)-\(match.2)-\(match.3)"
        }
        if let match = registerDt.wholeMatch(of: #/(\d{4})(\d{2})(\d{2})/#) {
            return "\(match.1)-\(match.2)-\(match.3)"
        }
        return nil
    }
}
