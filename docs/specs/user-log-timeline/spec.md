# Spec — 사용자 로그 인터페이스 흐름 (타임라인)

| 항목 | 내용 |
|---|---|
| 문서 상태 | 구현 완료 (변경 사항은 §10) |
| 작성일 | 2026-11-03 |
| 관련 문서 | [log-and-upload-viewer/spec.md](../log-and-upload-viewer/spec.md) (F1 사용자 로그, 네트워킹 공통 규칙) |
| 서버 기준 | `admin_golang` `07722a6` · `d0bd885` · `298b248` (2026-11-03) |
| 웹 기준 | `frontend/src/components/UserLogTimeline.tsx`, `frontend/src/utils/userLogTimeline.ts` |

**표기:** `P1`은 이번 범위에 꼭 포함, `P2`는 여유가 있으면 포함한다.

---

## 1. 범위 요약

admin_golang 웹의 User Log 화면에 추가된 **"인터페이스 흐름"** 탭을 iOS·macOS 앱에 옮긴다.
사용자 로그 파일(`UTxxxxxxxxxxx.log`)에서 다음을 뽑아 날짜·세션 단위의 시간순 목록으로 보여준다.

- ESB 연계 요청/응답 (V1 `EsbInterface.java`, V2 `EsbInterfaceV2.java`, MCI 마이데이터 호출 포함)
- MIDAS 연계 요청/응답 (`EsbServiceImpl.java`)
- API 진입 (`*Controller.java` 로그, V2 `LoggingAspect.kt`)
- WARN / ERROR 로그

**로그 파싱은 전부 서버가 한다.** 앱은 결과 JSON을 받아 묶기·필터·통계·표시만 한다.

### 목표
- G1. 사용자 문의가 오면 앱에서 바로 해당 사용자의 연계 호출 성공/실패와 응답시간을 확인한다.
- G2. 실패하거나 응답이 기록되지 않은 호출의 요청/응답 본문을 앱에서 열어본다.
- G3. 오류 조회 화면의 사용자 ID에서 흐름 분석으로 바로 들어간다.

### 비목표
- 앱에서 로그 파일을 직접 파싱하기 (서버 파서를 옮기지 않음)
- 여러 사용자, 여러 날짜를 한 번에 비교하기
- 실시간 로그 스트림과 타임라인을 자동으로 연동하기 (새 로그가 들어오면 타임라인 갱신 등)
- 결과 내보내기, 공유 (본문 복사만 지원)

---

## 2. 서버 API 계약

### `POST /admin/getUserLogTimeline/:no`

기존 사용자 로그 API와 같은 공통 규칙을 따른다 ([기존 spec §2.1](../log-and-upload-viewer/spec.md)).
query 파라미터 방식, `+`는 `%2B`로 인코딩, 200 + `text/html`이면 지원하지 않는 API, 401이면 토큰을 재발급받아 1회 재시도.

| 파라미터 | 위치 | 필수 | 설명 |
|---|---|---|---|
| `no` | path | O | 사용자 번호 (양의 정수, `UserLogNumber.value`) |
| `base` | query | X | 로그 경로 키 (`svr-was-test` · `gcgf-untact` · `gcgf-untact-stg`). 생략하면 서버가 자동 선택 |
| `date` | query | X | `YYYY-MM-DD`. 생략하거나 로그에 없는 날짜면 **가장 최근 날짜** |

권한은 `/admin/getUserLog`와 같다 (JWT subject가 `CI` 또는 `admin`).

#### 응답 200 (`application/json`)

```jsonc
{
  "file": "UT00000109114.log",
  "date": "2026-11-03",            // 실제로 선택된 날짜. 이벤트가 하나도 없으면 ""
  "dates": [                       // 로그에 있는 모든 날짜 (오래된 순)
    { "date": "2026-11-02", "count": 41, "failCount": 2, "incompleteCount": 1 }
  ],
  "events": [ /* 선택된 날짜의 이벤트, 시작 시각 순 */ ],
  "truncated": false               // 하루 이벤트가 3000건을 넘어 앞부분을 잘랐는지
}
```

`dates[].count`는 `log` 종류를 뺀 이벤트 수이고, `failCount`에는 ERROR 로그도 포함된다.

#### 이벤트

| 필드 | 타입 | 항상 있음 | 설명 |
|---|---|---|---|
| `seq` | Int | O | 날짜 안에서 1부터 매긴 순번. 화면에서 이벤트 ID로 쓴다 |
| `kind` | String | O | `esb` · `midas` · `api` · `log` |
| `status` | String | O | `ok` · `fail` · `incomplete`(응답 미기록) · `info` |
| `start` | String | O | `YYYY-MM-DD HH:mm:ss.SSS` (로그에 적힌 서버 현지 시각) |
| `startMs` | Int64 | O | `start`를 **UTC로 간주한** epoch ms. 정렬과 간격 계산에만 쓴다 (§5.3) |
| `end` | String | X | 종료 시각, `start`와 같은 형식 |
| `elapsedMs` | Int64 | X | 소요시간. 없으면 측정 불가 |
| `thread` | String | O | 스레드명. 복원하지 못하면 `unknown` |
| `source` | String | X | 소스 파일명에서 확장자를 뺀 것 (예: `EsbInterfaceV2`) |
| `level` | String | X | `log` 종류만: `WARN` · `ERROR` |
| `interfaceId` | String | X | ESB/MIDAS IF ID, API는 `Controller.method` 또는 URL |
| `name` | String | X | IF 명칭, API 이름, 로거 이름 |
| `httpStatus` | String | X | ESB HTTP 상태 (`"200"` 등, 문자열) |
| `resultCode` / `resultMsg` | String | X | 응답 본문의 `RLT_CODE` / `RLT_MSG` |
| `header` | String | X | MIDAS 요청 헤더, MCI URL, API URL 보조 정보 |
| `request` / `response` | String | X | 요청/응답 본문. 최대 2만 자이고, 넘으면 끝에 `\n... (생략됨)` |
| `message` | String | X | 오류 메시지, WARN/ERROR 본문, Controller 로그 |

서버에서 상태를 정하는 규칙 (참고용, 앱은 받은 값을 그대로 쓴다):
- `httpStatus`가 200이 아니거나, `resultCode`가 `000`이 아니거나, 응답의 `success`가 `Y`가 아니면 `fail`
- 같은 스레드에서 연계 중 ERROR가 나면 `fail`
- 응답 본문과 HTTP 상태가 모두 없으면 `incomplete`
- `api`와 WARN 로그는 `info`, ERROR 로그는 `fail`

#### 오류 응답

| 상황 | 응답 | 앱 처리 |
|---|---|---|
| 번호 형식 오류 | 400 `{"error":"Invalid user number"}` | 앱에서 미리 검증하므로 실제로는 나오지 않음 |
| 권한 없음 | 401 `{"error":"Unauthorized"}` | 토큰 재발급 후 1회 재시도, 그래도 실패하면 "인증 실패" |
| 로그 파일 없음 | 404 `{"error":"Log file not found"}` | "찾을 수 없음" + 사용자 번호·로그 경로 확인 안내 |
| 파싱 실패 | 500 `{"error":"Failed to parse log file"}` | "서버 오류" |
| 이 API가 없는 서버 | 200 `text/html` (SPA 폴백) 또는 404 텍스트 | "지원하지 않는 서버" / "찾을 수 없음" |

**빈 결과:** 로그 파일은 있는데 인식된 이벤트가 없으면 `date: ""`, `dates: []`, `events: []`. 오류가 아니라 빈 상태로 보여준다 (§6.4).

#### 응답 크기와 시간
- 서버는 로그 파일 **전체**를 읽어 파싱한 뒤 하루치만 돌려준다. 로그 파일이 크면 수 초 이상 걸릴 수 있다 → 요청 타임아웃을 **120초**로 잡는다.
- 최악의 경우 응답은 이벤트 3000건 × 본문 최대 4만 자. 실제로는 수 MB 이내로 예상하지만, 디코딩과 필터링을 메인 스레드에서 하지 않는다 (§5.4).

---

## 3. 아키텍처

### 3.1 계층

```
UserLogViewForIOS / UserLogSidebar + DetailViewForMac
        │  (보기 전환: 인터페이스 흐름 | 실시간 로그)
        ▼
UserLogTimelineView ── UserLogTimelineModel (@MainActor ObservableObject)
        │                       │
        │                       ├─ UserLogService.fetchTimeline  → NetworkClient.fetchJSON
        │                       └─ UserLogTimelineAnalysis (순수 함수: 묶기·필터·통계)
        ▼
TimelineEventRow / TimelineGroupHeader / TimelineEventDetailView
```

기존 F1(실시간 로그) 구조와 같게 한다. 서비스는 throw하고, 상태는 화면 모델이 갖고, 공통 화면은 `views/common/Ops/UserLog/`에 둔다.

### 3.2 설계 결정

| ID | 결정 | 이유 |
|---|---|---|
| D1 | 파싱은 서버, 묶기·필터·통계는 앱 | 웹과 같은 분담. 서버 파서(700줄 이상, 로그 형식이 바뀌면 계속 수정됨)를 두 곳에서 관리하지 않는다 |
| D2 | 웹 `userLogTimeline.ts`의 순수 함수를 Swift로 그대로 옮기고, 웹 테스트 케이스도 함께 옮긴다 | 웹과 묶음·통계 결과가 같아야 운영자가 혼동하지 않는다 |
| D3 | 화면 문구와 색은 웹과 맞춘다 (§6.5) | 웹과 앱을 같이 쓰는 운영자 |
| D4 | 이벤트 목록에는 본문을 표시하지 않고, 상세 화면에서만 표시한다 | 목록 성능, 모바일 화면 크기 |
| D5 | 실시간 로그와 흐름 분석은 같은 화면에서 전환하고, 전환해도 실시간 스트림을 끊지 않는다 | 웹 동작과 같음. 흐름을 보다가 실시간 로그로 돌아가는 경우가 많다 |
| D6 | 화면 시각은 `start` 문자열을 그대로 쓰고, `startMs`로 `Date`를 만들지 않는다 | `startMs`는 현지 시각을 UTC로 간주한 값이라 `Date`로 바꾸면 시간대만큼 틀어진다 |

### 3.3 파일 배치

```
MobileAdmin/
├── model/Ops/
│   ├── UserLogTimeline.swift              # NEW 응답 모델 (Decodable) + 열거형
│   └── UserLogTimelineAnalysis.swift      # NEW 세션/요청 묶기, 필터, 통계, 포맷 (순수 함수)
├── model/services/
│   ├── UserLogService.swift               # 수정: fetchTimeline 추가
│   └── NetworkClient.swift                # 수정: fetchJSON에 timeout 인자 추가
├── model/NavigationState.swift            # 수정: macOS 흐름 분석 요청, 보기 모드
├── views/common/Ops/UserLog/
│   ├── UserLogForm.swift                  # 수정: "흐름 분석" 버튼
│   ├── UserLogTimelineModel.swift         # NEW 화면 상태
│   ├── UserLogTimelineView.swift          # NEW 날짜·요약·필터·목록
│   ├── TimelineEventRow.swift             # NEW 이벤트 행, 묶음 헤더, 상태 배지
│   └── TimelineEventDetailView.swift      # NEW 메타, 헤더, 메시지, 요청/응답 본문
├── views/ios/ops/UserLogViewForIOS.swift  # 수정: 보기 전환
├── views/macos/
│   ├── UserLogSidebar.swift               # 수정: 흐름 분석 시작
│   ├── UserLogDetailForMac.swift          # NEW 상세 컬럼: 보기 전환 + 두 보기 유지
│   └── DetailViewForMac.swift             # 수정: UserLogDetailForMac 연결
└── views/common/ErrorCloud/ErrorCloudItemView.swift  # 수정: 흐름 분석 진입 (P2)

MobileAdminTests/
├── UserLogTimelineDecodingTests.swift     # NEW
└── UserLogTimelineAnalysisTests.swift     # NEW (웹 userLogTimeline.test.ts 대응)
```

---

## 4. 네트워킹

### 4.1 `NetworkClient.fetchJSON` timeout 인자

```swift
func fetchJSON<T: Decodable>(path: String,
                             query: [URLQueryItem] = [],
                             timeout: TimeInterval? = nil) async throws -> T
```

`fetchData`에는 이미 `timeout`이 있으므로 그대로 넘긴다. 기존 호출부는 바뀌지 않는다.

### 4.2 `UserLogService.fetchTimeline`

```swift
/// 인터페이스 흐름 — 서버가 로그 전체를 파싱하므로 타임아웃을 길게 잡는다
static let timelineTimeout: TimeInterval = 120

func fetchTimeline(number: UserLogNumber,
                   base: NasLogBase?,
                   date: String?) async throws -> UserLogTimeline
```

- path: `/admin/getUserLogTimeline/\(number.value)`
- query: `base`, `date`. 값이 nil이면 `makeURL`이 해당 항목을 빼므로 그대로 넘긴다 (`openTail`과 같은 방식).
- 디코딩은 `fetchJSON` 안에서 하고, 호출은 `Task.detached` 안에서 해서 메인 스레드를 막지 않는다 (§5.4).
- 실패하면 `logger.error`로 남기고 다시 throw한다. 취소는 기록하지 않는다 (`OpsError.isCancellation`).

---

## 5. 모델

### 5.1 응답 모델 (`UserLogTimeline.swift`)

```swift
enum TimelineKind: String, Decodable, CaseIterable, Hashable {
    case esb, midas, api, log
    case unknown                       // 서버에 새 종류가 생겨도 디코딩이 깨지지 않도록
}

enum TimelineStatus: String, Decodable, Hashable {
    case ok, fail, incomplete, info
    case unknown
}

struct TimelineEvent: Decodable, Identifiable, Hashable {
    let seq: Int
    let kind: TimelineKind
    let status: TimelineStatus
    let start: String
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
}

struct TimelineDate: Decodable, Hashable, Identifiable {
    let date: String
    let count: Int
    let failCount: Int
    let incompleteCount: Int
    var id: String { date }
}

struct UserLogTimeline: Decodable {
    let file: String
    let date: String
    let dates: [TimelineDate]
    let events: [TimelineEvent]
    let truncated: Bool
}
```

- 모르는 `kind` / `status` 값은 `.unknown`으로 디코딩한다 (`init(from:)`에서 `rawValue` 실패 시). `.unknown` 이벤트는 목록에 표시하되 종류 필터 대상에서는 빠진다.
- `dates`, `events`가 `null`로 와도 빈 배열로 처리한다 (`decodeIfPresent ?? []`). 현재 서버는 항상 배열을 주지만 방어적으로 처리한다.
- `Hashable`은 `seq`만으로 비교한다. 본문까지 비교하면 비용이 크다.

### 5.2 분석 함수 (`UserLogTimelineAnalysis.swift`)

웹 `userLogTimeline.ts`를 그대로 옮긴다. 이름은 Swift 관례에 맞추고, 동작은 같게 한다.

| 웹 | Swift | 내용 |
|---|---|---|
| `isCallEvent` | `TimelineEvent.isCall` | `esb` 또는 `midas` |
| `eventEndMs` | `TimelineEvent.endMs` | `startMs + (elapsedMs ?? 0)` |
| `groupTimelineSessions` | `TimelineAnalysis.sessions(_:gapMs:)` | 직전 세션 종료 후 **5분 이상** 비면 새 세션 |
| `groupTimelineRequests` | `TimelineAnalysis.requestGroups(_:gapMs:)` | 같은 스레드에서 이어진 이벤트를 하나의 요청 묶음으로. 직전 묶음 종료 후 **1.5초 초과** 공백이거나, 이미 `api` 이벤트가 있는 묶음에 새 `api`가 오면 새 묶음 |
| `filterTimelineEvents` | `TimelineAnalysis.filter(_:by:)` | 종류, 문제만(`fail`·`incomplete`), 검색어 |
| `computeTimelineStats` | `TimelineAnalysis.stats(_:)` | 연계 호출 수, 실패(ERROR 로그 포함), 미기록(연계만), 평균·최대 응답시간, 가장 느린 이벤트 |
| `formatDuration` | `TimelineFormat.duration(_:)` | `850ms` · `1.25s` · `12.5s` · `3분 5초` · `1시간 2분` · nil이면 `-` |
| `timeOfDay` | `TimelineFormat.timeOfDay(_:)` | `start`의 11번째 글자부터 (`HH:mm:ss.SSS`) |
| `shortThread` | `TimelineFormat.shortThread(_:)` | `http-nio-58080-exec-24` → `exec-24` |
| `prettyBody` | `TimelineFormat.prettyBody(_:)` | `{` 또는 `[`로 시작하는 유효한 JSON이면 2칸 들여쓰기 정렬(키 순서 유지), 아니면 원문 |

```swift
struct TimelineFilter: Equatable {
    var kinds: Set<TimelineKind> = [.esb, .midas, .api, .log]
    var problemsOnly = false
    var query = ""
}

struct TimelineRequestGroup: Identifiable {
    let id: String                 // "\(thread)-\(첫 이벤트 seq)"
    let thread: String
    var events: [TimelineEvent]
    var entry: TimelineEvent?      // 묶음 안의 첫 api 이벤트
    var startMs: Int64
    var endMs: Int64
    var callCount: Int
    var failCount: Int
    var incompleteCount: Int
}

struct TimelineSession: Identifiable { /* id, startMs, endMs, events, callCount, failCount, incompleteCount, maxElapsedMs */ }

struct TimelineStats: Equatable { /* callCount, failCount, incompleteCount, avgElapsedMs, maxElapsedMs, slowest: TimelineEvent? */ }
```

검색 대상 필드: `interfaceId`, `name`, `thread`, `resultCode`, `resultMsg`, `message`, `request`, `response`. 대소문자 구분 없이 부분 일치 (`localizedCaseInsensitiveContains` 대신 `range(of:options: .caseInsensitive)`로 처리해 웹과 결과를 맞춘다).

**적용 순서 (웹과 동일):**
1. 통계 → **필터 전** 전체 이벤트 기준 (필터를 바꿔도 요약 숫자는 그대로)
2. 필터 → 필터된 이벤트로 세션 묶기 → 세션마다 (스레드 묶기가 켜져 있으면) 요청 묶기

### 5.3 시각 처리

- 화면 시각은 `TimelineFormat.timeOfDay(event.start)`처럼 문자열을 그대로 잘라 쓴다 (D6).
- 세션 시작·종료처럼 `startMs`에서 시각을 만들어야 할 때는 `TimeZone(identifier: "UTC")`로 포맷한다. 그러면 로그에 적힌 현지 시각과 같은 값이 나온다.

### 5.4 성능

- 디코딩: `fetchJSON`이 `Task.detached` 안에서 실행되도록 모델에서 호출한다.
- 파생 데이터(필터 결과, 세션, 요청 묶음)는 `@Published`로 캐시하고, 필터나 데이터가 바뀔 때만 다시 계산한다. `body`에서 매번 계산하지 않는다.
- 검색어 입력은 **300ms 디바운스**를 걸고, 본문까지 뒤지는 필터는 백그라운드에서 계산한 뒤 메인에서 반영한다. 계산 중 필터가 또 바뀌면 이전 작업을 취소한다.
- 목록은 `List`(iOS) / `LazyVStack`(macOS)로 화면에 보이는 행만 그린다.

---

## 6. 화면

### 6.1 화면 상태 모델 (`UserLogTimelineModel`)

```swift
@MainActor
final class UserLogTimelineModel: ObservableObject {
    enum Phase: Equatable { case idle, loading, loaded, failed }

    @Published private(set) var request: UserLogTimelineRequest?   // 번호, 경로
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var error: Error?
    @Published private(set) var data: UserLogTimeline?             // 다시 불러오는 중에도 이전 결과 유지
    @Published private(set) var stats: TimelineStats?
    @Published private(set) var sessions: [TimelineSessionView] = []  // 필터 + 세션 + 요청 묶음 결과
    @Published var filter = TimelineFilter()
    @AppStorage("userLog.timeline.groupByThread") var groupByThread = true
    @Published var selectedSeq: Int?
    @Published var collapsedGroups: Set<String> = []

    func load(_ request: UserLogTimelineRequest)   // 새 대상: 날짜 nil(최근), 필터 유지, 선택·접힘 초기화
    func select(date: String)                      // 같은 대상의 다른 날짜
    func reload()                                  // 현재 대상 + 현재 날짜 다시 불러오기
    func focus(seq: Int)                           // 선택하고, 그 이벤트가 들어 있는 묶음을 펼친다
    func cancel()
}

struct UserLogTimelineRequest: Hashable {
    let number: UserLogNumber
    let base: NasLogBase?
    let requestedAt: Date      // 같은 대상을 다시 분석해도 값이 달라지도록 (UserLogTarget과 같은 방식)
}
```

- 새 요청이 오면 진행 중인 요청을 취소한다. 응답이 늦게 도착해 순서가 뒤바뀌는 것을 막기 위해, 응답의 요청 정보가 현재 요청과 다르면 버린다.
- 날짜를 바꾸거나 다시 불러오는 동안 이전 결과를 그대로 보여주고 상단에 진행 표시만 띄운다 (웹과 동일).

### 6.2 진입

| 진입점 | 동작 |
|---|---|
| `UserLogForm` "흐름 분석" 버튼 (P1) | 입력한 번호와 경로로 분석. 기존 "실시간 보기" 버튼 앞에 둔다. 번호가 올바르지 않으면 비활성 |
| `UserLogForm` 번호 입력 후 Return | 지금처럼 **실시간 보기**를 시작한다 (기존 동작 유지) |
| 오류 조회의 사용자 ID (P2) | 기존 "실시간 로그" 버튼 옆에 "흐름 분석" 버튼 추가 |

`UserLogForm`에 `var onAnalyze: (UserLogNumber, NasLogBase?) -> Void` 인자를 추가한다. 초기 줄 수 선택은 흐름 분석에는 쓰지 않는다.

### 6.3 플랫폼별 배치

**iOS — `UserLogViewForIOS`**
- 입력 폼 아래에 보기 전환 `Picker(.segmented)`: **인터페이스 흐름 | 실시간 로그**
- "흐름 분석"을 누르면 흐름 보기로, "실시간 보기"를 누르면 실시간 보기로 전환하고 폼을 접는다.
- 두 모델(`UserLogTailModel`, `UserLogTimelineModel`)을 모두 `@StateObject`로 들고 있으므로 보기를 바꿔도 상태가 유지된다 (D5).
- 이벤트를 누르면 `TimelineEventDetailView`로 push한다.
- `UserLogViewForIOS(initialNumber:initialMode:)` — 오류 조회에서 들어올 때 모드를 지정한다. 기본값은 지금처럼 `.stream`.
- 화면 제목은 기존 `SlidebarItem.userLogTail.title` 그대로 둔다. 메뉴 설명 문구는 "사용자 로그 흐름 분석 · 실시간 확인"으로 바꾼다.

**macOS — `UserLogSidebar` + `DetailViewForMac`**
- `NavigationState`에 추가:
  ```swift
  @Published var userLogTimelineRequest: UserLogTimelineRequest?
  @Published var userLogViewMode: UserLogViewMode = .timeline   // enum UserLogViewMode { case timeline, stream }
  ```
- 사이드바의 "흐름 분석" → `userLogTimelineRequest` 설정 + 모드 `.timeline`. "실시간 보기" → 지금처럼 `userLogTarget` 설정 + 모드 `.stream`.
- 상세 컬럼 툴바에 보기 전환 `Picker(.segmented)`. 선택한 모드의 대상이 없으면 그 모드의 빈 상태를 보여준다.
- 실시간 화면(`UserLogTailScreen`)과 흐름 화면을 둘 다 살려 두고 보이는 것만 바꾼다 (D5). `UserLogTimelineModel`은 상세 컬럼에서 `@StateObject`로 들고, 요청이 바뀌면 `load`한다.
- 이벤트를 선택하면 `.inspector`(macOS 14+, 배포 대상 14.6)로 오른쪽에 상세를 보여준다. 폭은 최소 360pt.
- 사이드바 설명 문구: "사용자 번호를 입력하고 흐름 분석 또는 실시간 보기를 시작하세요."

### 6.4 `UserLogTimelineView` 구성 (위에서 아래로)

1. **날짜 바** — 가로 스크롤 칩. 칩마다 `MM-dd` + 호출 수, 실패가 있으면 빨간 숫자, 미기록이 있으면 주황 숫자. 선택된 날짜를 강조하고 처음 그릴 때 그 칩으로 스크롤한다. 오른쪽 끝에 새로고침 버튼. 파일명(`file`)은 날짜 바 위에 작게 표시한다.
2. **잘림 안내** — `truncated`이면 `OpsBanner`로 "이벤트가 많아 마지막 3000건만 표시합니다."
3. **요약** — `연계 호출` · `실패` · `응답 미기록` · `평균 응답` · `최대 응답`. iOS는 가로 스크롤 한 줄, macOS는 5칸 그리드. `최대 응답`을 누르면 가장 느린 이벤트로 이동한다 (`focus`).
4. **필터** — 검색창(placeholder "IF ID, 명칭, 요청/응답 내용 검색"), 종류 토글 4개(`ESB` · `MIDAS` · `API 진입` · `WARN/ERROR`), `문제만` 토글, `스레드별 묶기` 토글. iOS는 검색창을 `.searchable`로, 나머지는 필터 메뉴(`Menu`) 하나로 모은다.
5. **목록** — 세션 단위 Section.
   - 세션 헤더: `HH:mm:ss ~ HH:mm:ss` · 길이 · 호출 n건 · 실패 n · 미기록 n
   - 세션 시간 막대 (`SessionStrip`, **P2**): 세션 구간 안에서 이벤트 위치와 길이를 막대로 표시하고, 누르면 그 이벤트로 이동
   - 스레드별 묶기가 켜져 있으면 요청 묶음마다 접을 수 있는 헤더: 시작 시각, 짧은 스레드명, 진입 API(`entry.name ?? entry.interfaceId`), `n건 · 연계 n`, 전체 소요, 실패·미기록 배지. 진입 API가 없으면 "같은 스레드 연속 처리"
   - 이벤트 행 (§6.5)

| 상태 | 표시 |
|---|---|
| 처음 (요청 없음) | `EmptyStateView` "사용자 번호를 입력하고 흐름 분석을 시작하세요." |
| 첫 로딩 | `ProgressView("로그를 분석하는 중...")` |
| 오류 | `OpsErrorView` + 다시 시도. 404 안내: "사용자 번호와 로그 경로를 확인하세요." (`notFoundHint`) |
| 결과 없음 (`dates` 비어 있음) | "인터페이스 이력이 없습니다." |
| 필터 결과 없음 | "조건에 맞는 이벤트가 없습니다." + 필터 초기화 버튼 |

### 6.5 이벤트 행 (`TimelineEventRow`)

한 줄 구성 (iOS는 두 줄로 줄바꿈 허용):

```
[시각 HH:mm:ss.SSS] [종류 칩] [IF ID] [명칭 …]          [소요시간 막대] [상태 배지]
```

- **종류 칩:** `ESB`(파랑), `MIDAS`(보라), `API`(초록), `WARN`(주황) / `ERROR`(빨강)
- **상태 배지:**
  - `fail` → 빨강 "실패", `resultCode`가 있으면 "실패 E001"
  - `incomplete` → 주황 "응답 미기록"
  - `api` + `info` → 회색 "진입"
  - `ok`는 배지 없음
- **소요시간:** `formatDuration(elapsedMs)`. 연계 호출이면 같은 날짜의 최대 응답시간 대비 비율로 막대를 그린다 (macOS만, iOS는 숫자만).
- `api` 행의 소요시간은 Controller 전체 처리 시간이다.
- 스레드명은 macOS에서만 짧게 표시 (`shortThread`).
- 선택된 행을 강조한다. `focus`로 이동하면 해당 행으로 스크롤한다 (`ScrollViewReader`).

### 6.6 이벤트 상세 (`TimelineEventDetailView`)

1. **메타** (값이 있는 것만): `IF ID`, `명칭`, `시작`, `종료`, `소요`, `스레드`(전체 이름), `HTTP`, `RLT_CODE`, `RLT_MSG`, `소스`
2. **헤더** (`header`) — 고정폭 글꼴 블록
3. **메시지** (`message`) — 주황 배경 고정폭 블록
4. **요청 → / ← 응답** — `log` 종류가 아니면 표시. `prettyBody`로 정렬한 고정폭 텍스트, 텍스트 선택 가능, 각 블록에 복사 버튼(복사 후 토스트). 내용이 없으면 "(기록 없음)". 2만 자 본문도 버벅이지 않도록 `Text` 대신 기존 로그 뷰어의 텍스트 표시 방식(`LogLinesView` 등)을 재사용할 수 있는지 구현 때 확인한다.
5. macOS는 요청/응답을 좌우로, iOS는 위아래로 배치한다.

---

## 7. 테스트

Apple Testing 프레임워크(`@Test`)를 쓴다. 테스트 타깃 복구(기존 tasks T0.1) 전에는 기존과 같이 SwiftPM 하네스로 실행한다.

**디코딩 (`UserLogTimelineDecodingTests`)**
- 모든 필드가 있는 이벤트, 필수 필드만 있는 이벤트
- 모르는 `kind` / `status` → `.unknown`
- `dates` / `events`가 `null`이거나 빠져 있을 때 빈 배열
- 빈 결과 (`date: ""`)
- 서버 테스트(`services/user_log_timeline_test.go`) 기대값으로 만든 JSON 샘플 1개를 그대로 디코딩

**분석 (`UserLogTimelineAnalysisTests`)** — 웹 `frontend/test/userLogTimeline.test.ts`의 케이스를 하나씩 옮긴다.
- 세션: 5분 경계에서 정확히 분리, 세션 통계(호출 수, 실패, 미기록, 최대 응답)
- 요청 묶음: 같은 스레드 1.5초 이내 연속은 하나로, 1.5초 초과면 분리, 두 번째 `api`면 분리, 스레드가 다르면 시간이 겹쳐도 분리, `entry` 지정
- 필터: 종류, 문제만, 검색어 (대소문자, 본문 검색, 필드가 nil일 때)
- 통계: `elapsedMs` 없는 이벤트는 평균에서 제외, 평균 반올림, ERROR 로그도 실패 수에 포함
- 포맷: `formatDuration` 경계값 (999ms, 1000ms, 9999ms, 10s, 60s, 1시간), `shortThread`, `prettyBody`(JSON, 비JSON, 깨진 JSON)

**모델 (`UserLogTimelineModel`)** — 서비스를 주입할 수 있게 만들고:
- 늦게 도착한 이전 요청의 응답을 버리는지
- 날짜를 바꾸는 동안 이전 결과를 유지하는지
- `focus`가 접힌 묶음을 펼치는지

**수동 QA**
- 실제 서버(개발 환경)에서 V1 로그 사용자와 V2 로그 사용자 각각 1명 이상
- 이벤트가 많은 사용자(3000건에 가까움)로 스크롤, 검색 반응 속도 확인 (iPhone 실기기)
- 이 API가 없는 서버에 연결했을 때 "지원하지 않는 서버" 표시
- 실시간 보기 중 흐름 보기로 전환 → 다시 돌아왔을 때 스트림이 계속 이어지는지

---

## 8. 미결 사항

| # | 내용 | 기본안 |
|---|---|---|
| Q1 | 운영 서버에 `getUserLogTimeline`이 언제 배포되는지 | 배포 전에도 앱은 "지원하지 않는 서버"로 안전하게 처리되므로 앱 작업은 먼저 진행 |
| Q2 | 큰 로그 파일에서 서버 응답 시간 | 개발 서버에서 큰 로그로 측정. 120초가 부족하면 서버 쪽 개선(날짜 범위 먼저 읽기 등)을 따로 요청 |
| Q3 | 웹은 흐름 분석 탭이 기본인데, 앱도 기본 보기를 흐름 분석으로 바꿀지 | 마지막으로 쓴 모드를 `@AppStorage("userLog.viewMode")`로 기억. 처음에는 흐름 분석 |
| Q4 | 세션 시간 막대(P2)를 iOS 좁은 화면에서도 보여줄지 | macOS만 먼저, iOS는 QA 후 결정 |
| Q5 | 오류 조회 화면에서 흐름 분석으로 들어갈 때 오류 발생 날짜를 `date`로 넘길지 | 넘긴다 (오류 항목의 등록일 → `YYYY-MM-DD`). 로그에 그 날짜가 없으면 서버가 최근 날짜로 대체 |

---

## 9. 작업 단위 (요약)

자세한 태스크는 tasks.md에서 나눈다.

| 단계 | 내용 | 크기 |
|---|---|---|
| 1 | 응답 모델 + 분석 함수 + 단위 테스트 (§5, §7) | M |
| 2 | `fetchJSON` timeout, `UserLogService.fetchTimeline` (§4) | S |
| 3 | `UserLogTimelineModel` (§6.1) | M |
| 4 | 공통 화면: 목록, 행, 상세 (§6.4 ~ 6.6) | L |
| 5 | iOS·macOS 연결, `UserLogForm` 버튼, 보기 전환 (§6.2, §6.3) | M |
| 6 | P2: 오류 조회 진입, 세션 시간 막대, 소요시간 막대 | M |
| 7 | 문서 갱신 (CLAUDE.md 구조), 수동 QA | S |

---

## 10. 구현 중 변경 사항 (2026-11-03)

| 항목 | spec 초안 | 구현 | 이유 |
|---|---|---|---|
| `prettyBody` | `Util.prettyPrintedJSON` 재사용 | 직접 구현 (`TimelineFormat.reindentJSON`) | 기존 함수는 `JSONSerialization`을 써서 키 순서가 바뀌고, 객체만 처리하며, 잘린 JSON을 임의로 보정한다. 웹(`JSON.stringify`)처럼 키 순서를 유지해야 요청/응답 비교가 쉽다 |
| 보기 모드 저장 | `NavigationState.userLogViewMode` | `@AppStorage(UserLogViewMode.storageKey)` 하나를 사이드바·상세·오류 상세가 함께 사용 | 마지막 보기 기억(Q3)과 macOS 상태 공유를 한 번에 해결 |
| `UserLogTimelineRequest` | 번호, 경로 | 번호, 경로, **날짜** | 오류 상세에서 오류 발생일로 열기(Q5) |
| `UserLogTimelineModel` | — | `reset()` 추가 | macOS 사이드바에서 흐름 대상을 닫을 때 |
| `UserLogForm` 버튼 | "흐름 분석" 추가 | "흐름 분석"(주 버튼) + "실시간 보기"(보조) | 웹과 같은 우선순위. 기존 "시작" 문구는 어떤 보기인지 모호해서 바꿈 |
| iOS 상세 push | — | push할 때 스트림을 멈추고 돌아오면 다시 연결 | iOS는 push하면 화면에 `onDisappear`가 호출된다. 화면 밖에 연결을 남기지 않는 기존 원칙 유지 |
| macOS `UserLogTailScreen` | — | `navigationTitle` 제거, 제목은 `UserLogDetailForMac`이 정함 | 두 보기를 겹쳐 둘 때 제목 충돌 방지 |
| iOS 오류 목록 패널 | — | "흐름 분석" 링크 추가 | 오류 상세와 같은 진입점 |
