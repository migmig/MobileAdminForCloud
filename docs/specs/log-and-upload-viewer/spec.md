# Spec — 로그 · 업로드 파일 뷰어

| 항목 | 내용 |
|---|---|
| 문서 상태 | v1 구현 반영 (§14 변경 사항 참고) |
| 작성일 | 2026-11-01 |
| 관련 문서 | [prd.md](./prd.md) · [tasks.md](./tasks.md) |
| 기준 코드 | 앱 `main@3aae783`, 서버 `admin_golang@656c749` |

PRD의 기능 ID(F1-x, F2-x, F3-x, C-x)를 그대로 사용한다.

---

## 1. 범위 요약

| 기능 | 서버 엔드포인트 | 앱 화면 |
|---|---|---|
| F1 사용자 로그 실시간 보기 | `getUserLogTail/:no`, `getUserLog/:no` | iOS `UserLogViewForIOS` / macOS `UserLogSidebar` + `UserLogTailView` |
| F2 서버 로그 뷰어 | `log/{kind}/folders`, `files`, `content`, `download` | iOS 3단 드릴다운 / macOS `ServerLogSidebar` + `ServerLogContentView` |
| F3 업로드 브라우저 | `upload/list`, `upload/file` | iOS `UploadBrowserViewIOS`(재귀) / macOS `UploadBrowserSidebar` + `UploadFileDetailView` |

다음 엔드포인트는 사용하지 않는다: `log/*/organize`, `log/*/zip`.

---

## 2. 서버 API 계약

### 2.1 공통 규칙 (모든 엔드포인트)

| 규칙 | 내용 | 클라이언트 영향 |
|---|---|---|
| 메서드 | 전부 **POST**. 파라미터는 **query string**으로 받는다(바디 없음) | `makeAuthenticatedRequest`가 이미 POST를 쓴다 |
| 인증 | `Authorization: Bearer <JWT>`. 실패하면 401 `{"status":"error","message":"..."}` | C-4: 401이면 토큰을 리셋하고 1회 재시도 |
| 핸들러 오류 형식 | `{"error":"<msg>"}` | 두 가지 오류 형식을 모두 파싱한다(`ServerErrorBody`) |
| 존재하지 않는 경로 | 404가 아니라 SPA `index.html`이 **200 `text/html`**로 온다 | 200이어도 `Content-Type: text/html`이면 `unsupportedEndpoint`로 처리한다(C-3) |
| `+` 문자 | Go `url.ParseQuery`는 `+`를 공백으로 해석한다 | query의 `+`를 반드시 `%2B`로 인코딩한다 |
| 시각 | `modTime`은 **Unix 초**(`int64`) | `Date(timeIntervalSince1970:)` |
| 크기 | `size`는 바이트(`int64`) | `Int64` |
| 빈 목록 | 성공 응답에서 배열은 `[]`이며 `null`이 아니다 | non-optional 배열로 디코딩 |
| 타임아웃 | 서버 쪽 read/write 타임아웃 없음, heartbeat 없음 | tail 요청에 긴 타임아웃 적용 |

### 2.2 F1 — 사용자 로그

**공통**
- `:no`는 양의 정수여야 한다. 그렇지 않으면 400 `{"error":"Invalid user number"}`.
- 토큰의 `sub`는 `admin` 또는 CI 값이어야 한다. 그렇지 않으면 401 `{"error":"Unauthorized"}`.
- 서버의 파일 경로는 `<base>/<bucket>/UT%011d.log`이다. bucket은 `max(1000, (no/1000)*1000)`.
- 파일이 없으면 404 `{"error":"Log file not found"}`. 그 밖의 열기 실패는 500 `{"error":"failed to open log file: ..."}`.

**`base` query (선택)**

| 값 | 의미 |
|---|---|
| (생략) | 자동. 서버 기동 시 결정되며 `gcgf-untact`를 우선한다 |
| `gcgf-untact` | `/mnt/nas/logs/gcgf-untact/users` |
| `gcgf-untact-stg` | `/mnt/nas/logs/gcgf-untact-stg/users` |
| `svr-was-test` | `/mnt/nas/logs/svr-was-test/gcgf_untact/users` |

#### `POST /admin/getUserLogTail/:no`

| query | 타입 | 기본값 | 범위 |
|---|---|---|---|
| `lines` | int | 200 | 1~1000. 1000을 넘으면 1000으로 잘린다. 0 이하이거나 숫자가 아니면 200 |
| `follow` | bool | true | `0`, `false`, `no`일 때만 false |
| `base` | string | — | 위 표 참조 |

- **200 응답:** `text/plain; charset=utf-8`, chunked(Content-Length 없음).
- **헤더:** `X-User-Log-File: UT00000109114.log`.
- **바디:** 마지막 N줄(각 줄 끝에 `\n`)을 보낸 뒤 flush하고, 이후 100ms 주기로 파일 끝에 추가된 내용을 보낸다.
- **청크는 줄 경계와 일치하지 않는다.** 클라이언트가 직접 버퍼링해서 `\n`으로 나눠야 한다.
- 스트림은 클라이언트가 연결을 끊을 때만 끝난다.
- 로그 로테이션을 감지하지 않는다. 파일이 교체되면 스트림이 조용해진다. 그래서 재연결 UI가 필요하다.
- 오류(400/401/404/500)는 스트림 시작 **전에** JSON으로 온다.

#### `POST /admin/getUserLog/:no`

- 200 응답은 `application/octet-stream`이다. 헤더는 `Content-Disposition: attachment; filename=UT….log`(따옴표 없음)와 `Content-Length`.
- `base` query를 지원한다.

### 2.3 F2 — 서버 로그 (4종)

| kind | prefix | `base` query | 기본 경로 |
|---|---|---|---|
| backend | `/admin/log/backend` | 지원. 값은 `svr-was-test`(기본, 알 수 없는 값도 이것으로 처리), `gcgf-untact`, `gcgf-untact-stg` | `/mnt/nas/logs/svr-was-test/gcgf_untact` 등 |
| oauthResource | `/admin/log/oauth/resource` | 무시 | `/mnt/nas/resource/logs` |
| oauthAuth | `/admin/log/oauth/auth` | 무시 | `/mnt/nas/authorization/logs` |
| mobileid | `/admin/log/mobileid` | 무시 | `/mnt/nas/logs/mobileid` |

**이름 검증(`validateSafeName`):** 앞뒤 공백을 제거한 뒤 빈 값, `.`, `..`, `/`나 `\`가 들어간 값이면 400. 폴더는 한 단계만 가능하다.

**Entry:** `{"name": String, "size": Int64, "modTime": Int64}`. `isDir`는 없다. 폴더와 파일은 서로 다른 엔드포인트에서 받는다.

**정렬:** `modTime` 내림차순, 같으면 `name` 내림차순. 점(`.`)으로 시작하는 항목은 숨긴다.

#### `POST {prefix}/folders` — query `base`(backend만)

```json
{"base":"/mnt/nas/logs/svr-was-test/gcgf_untact",
 "folders":[{"name":"2026-10","size":4096,"modTime":1761955200}]}
```
- 기준 경로가 없는 경우를 포함해 모든 읽기 오류는 **500** `{"error":"..."}`이다. 404는 없다.

#### `POST {prefix}/files` — query `folder`(생략하면 루트), `base`

```json
{"base":"/mnt/nas/resource/logs","folder":"2026-10",
 "files":[{"name":"app_2026-10-31_0.log.gz","size":182734,"modTime":1761955199}]}
```
- 오류: 400 `invalid folder name` / 404 `folder not found` / 500.

#### `POST {prefix}/content` — query `name`(필수), `folder`, `tail`, `base`

| query | 기본값 | 범위 |
|---|---|---|
| `tail` | 1000 | 1~10000. 10000을 넘으면 10000으로 잘린다. 0 이하이거나 숫자가 아니면 1000 |

- **200 응답:** `text/plain; charset=utf-8`. 스트리밍이 아니며 응답이 끝까지 온다.
- **헤더:**
  - `X-Log-File`: 파일 이름
  - `X-Log-Tail-Lines`: 반환한 줄 수. 표식 줄은 제외한다
  - `X-Log-Truncated: true`: 잘렸을 때만 붙는다
- **잘렸을 때:** 바디 첫 줄이 표식 줄 `... (앞부분 생략, 최근 {N}줄만 표시) ...`이다.
- **`.gz`:** 서버가 압축을 풀어서 보낸다. 파일 전체를 스캔하므로 큰 `.gz` 파일은 느릴 수 있다.
- **오류:** 400 `invalid file name` / 400 `invalid folder name` / 404 `file not found` / 400 `not a file` / 500(gzip 손상, 1MiB를 넘는 줄 등).

#### `POST {prefix}/download` — query `name`(필수), `folder`, `base`

- **200 응답:** 원본 그대로 온다. `.gz`도 압축을 풀지 않는다. `Content-Encoding`이 없으므로 URLSession이 자동으로 풀지 않는다.
- **Content-Type:** `.gz`는 `application/gzip`, `.log`와 `.txt`는 `text/plain`, 나머지는 `application/octet-stream`.
- **헤더:** `Content-Length`, `Content-Disposition: attachment; filename="<name>"`.
- **오류:** content와 같다.

### 2.4 F3 — 업로드

**`path` query**
- `/`로 구분한 상대 경로이며, 앞뒤 `/`를 제거한다. `""` 또는 `.`이면 루트.
- **각 세그먼트**에 `validateSafeName`을 적용한다. 그래서 `..`, `a//b`처럼 빈 세그먼트가 생기는 경로, `\`가 들어간 경로는 400이 된다.

**Entry:** `{"name": String, "isDir": Bool, "size": Int64, "modTime": Int64}`.

#### `POST /admin/upload/list` — query `path`

```json
{"base":"/mnt/nas/upload","path":"app/20251205_105727",
 "entries":[{"name":"thumbs","isDir":true,"size":4096,"modTime":1764900000},
            {"name":"foo.png","isDir":false,"size":20480,"modTime":1764899000}]}
```
- **정렬:** 디렉터리가 먼저 오고, 그 안에서 `modTime` 내림차순, 같으면 `name` **오름차순**. 로그 목록과 반대이니 주의.
- **오류:** 400 `invalid path` / 404 `path not found` / 500. 대상이 파일이면 500.

#### `POST /admin/upload/file` — query `path`(필수)

- **200 응답:**
  - `Content-Type`은 확장자로 추정한다.
  - `Content-Disposition`은 `text/*`, `image/*`, `application/pdf`, `json`, `xml`, `javascript`이면 `inline`, 그 외는 `attachment`. `filename="<basename>"`은 RFC 5987 인코딩이 아니라 한글이 그대로 들어온다.
  - `Content-Length`와 Range를 지원한다.
- 서버 쪽 크기 제한은 없다.
- POST와 Bearer 인증이 필요하다. 그래서 `AVPlayer(url:)`로 바로 재생할 수 없다. 반드시 로컬 파일로 받은 뒤 미리보기한다.
- **오류:** 400 `invalid path` / 404 `file not found` / 400 `not a file` / 500.

---

## 3. 아키텍처

### 3.1 계층

```
View (iOS / macOS / common)
  │  @StateObject
  ▼
Feature State Model (@MainActor ObservableObject)   ← 신규: 화면 단위 상태와 수명주기
  │  UserLogTailModel · ServerLogContentModel · UploadBrowserModel …
  ▼
Service (struct)                                    ← UserLogService(확장), ServerLogService, UploadService
  │
  ▼
NetworkClient (class)                               ← 확장: URL 빌더, 응답 검증, 파일 다운로드, 스트림, 401 재시도
```

### 3.2 설계 결정

| ID | 결정 | 이유 |
|---|---|---|
| D1 | 새 기능의 상태는 전역 `ViewModel`에 `@Published`로 두지 않는다. 화면 단위 `@MainActor` 상태 모델이 서비스를 직접 소유한다 | tail 스트림처럼 수명이 화면에 묶인 상태를 전역에 두면 화면을 벗어나도 남아서 누수가 생기고, 플랫폼 간에 공유되는 문제가 생긴다. `NetworkClient`의 토큰은 static이라 인스턴스를 여러 개 만들어도 인증 상태를 공유한다 |
| D2 | 새 서비스는 오류를 삼키지 않고 **throw**한다 | G5/C-5: 404, 미지원 서버, 권한 오류를 구분해서 표시해야 한다. 기존 서비스의 "빈 기본값 반환" 관례와 다르다는 점을 주석에 남긴다 |
| D3 | `NetworkClient`에 `session: URLSession` 주입점을 추가한다(기본값 `.shared`) | `URLProtocol` 스텁으로 테스트하기 위해서다. 기존 호출부는 바꾸지 않는다 |
| D4 | 스트림의 줄 분할은 `AsyncBytes.lines` 대신 직접 구현한 `LineSplitter`로 한다 | `AsyncBytes.lines`는 빈 줄이 누락되는 사례가 있다. UTF-8 멀티바이트 경계, `\r\n`, 최대 줄 길이도 직접 제어할 수 있다 |
| D5 | 파일 미리보기는 SwiftUI `.quickLookPreview(_:)`로 통일한다(iOS와 macOS 모두) | 의존성을 추가하지 않고 이미지, PDF, 텍스트, 동영상을 처리할 수 있다 |
| D6 | 토스트를 쓰지 않는다. 결과와 오류는 화면 안의 상태 영역(배너, `EmptyStateView`)으로 표시한다 | iOS에는 토스트 modifier가 적용되어 있지 않고, macOS에서도 콘텐츠 컬럼에는 주입되지 않는다(현행 구조) |

### 3.3 파일 배치

`PBXFileSystemSynchronizedRootGroup`을 쓰므로 `MobileAdmin/` 아래에 파일만 추가하면 타깃에 자동으로 포함된다.

```
MobileAdmin/
├── model/
│   ├── NetworkError.swift                      (수정) 케이스 추가
│   ├── NavigationState.swift                   (수정) 선택 상태 추가
│   ├── Ops/                                    (신규 폴더)
│   │   ├── OpsCommon.swift                     NasLogBase, ServerErrorBody
│   │   ├── ServerLogModels.swift               ServerLogKind, LogEntry, LogFolderListResponse, LogFileListResponse, ServerLogFileRef
│   │   ├── LogText.swift                       LogLine, LogContent
│   │   ├── UserLogTarget.swift                 UserLogTarget, UserLogNumber
│   │   └── UploadModels.swift                  UploadEntry, UploadListResponse, UploadEntryRef, UploadPath
│   └── services/
│       ├── NetworkClient.swift                 (수정)
│       ├── UserLogService.swift                (수정)
│       ├── ServerLogService.swift              (신규)
│       └── UploadService.swift                 (신규)
├── Util/
│   ├── Util.swift                              (수정) formatFileSize, formatUnixTime
│   ├── LineSplitter.swift                      (신규)
│   └── DownloadStore.swift                     (신규)
├── views/
│   ├── common/Ops/                             (신규 폴더)
│   │   ├── LogLinesView.swift                  공용 로그 텍스트 뷰어
│   │   ├── LogSearchBar.swift
│   │   ├── LogBasePicker.swift
│   │   ├── FileEntryRow.swift
│   │   ├── OpsErrorView.swift                  오류/미지원 상태 뷰와 메시지 매핑
│   │   ├── DownloadedFileActions.swift         미리보기/공유/Finder 버튼 묶음
│   │   ├── UserLog/
│   │   │   ├── UserLogTailModel.swift
│   │   │   ├── UserLogForm.swift
│   │   │   └── UserLogTailView.swift
│   │   ├── ServerLog/
│   │   │   ├── ServerLogContentModel.swift
│   │   │   └── ServerLogContentView.swift
│   │   └── Upload/
│   │       ├── UploadBrowserModel.swift
│   │       └── UploadFileDetailView.swift
│   ├── ios/ops/                                (신규 폴더)
│   │   ├── UserLogViewForIOS.swift
│   │   ├── ServerLogKindListViewIOS.swift
│   │   ├── ServerLogFolderListViewIOS.swift
│   │   ├── ServerLogFileListViewIOS.swift
│   │   └── UploadBrowserViewIOS.swift
│   └── macos/
│       ├── UserLogSidebar.swift                (신규)
│       ├── ServerLogSidebar.swift              (신규)
│       └── UploadBrowserSidebar.swift          (신규)
```

`views/macos/` 파일도 iOS로 함께 컴파일된다(단일 멀티플랫폼 타깃). 그래서 AppKit API를 쓰는 부분은 `#if os(macOS)`로 감싼다.

---

## 4. 네트워킹 확장

### 4.1 `NetworkError` 추가 케이스

```swift
enum NetworkError: LocalizedError {
    // 기존 케이스 유지 …
    /// 서버가 JSON 오류 바디({"error"} 또는 {"message"})와 함께 실패 응답을 준 경우
    case server(statusCode: Int, message: String?, url: String)
    /// 200이지만 HTML(SPA 폴백) 응답 — 현재 서버가 해당 API를 지원하지 않음
    case unsupportedEndpoint(url: String)
    /// 응답 Content-Type이 기대와 다름
    case unexpectedContentType(String?, url: String)
}
```

`errorDescription`:
- `server`: message가 있으면 message, 없으면 `"HTTP 오류 \(code)"`.
- `unsupportedEndpoint`: `"현재 서버에서 지원하지 않는 기능입니다"`.

### 4.2 `NetworkClient` 확장 API

```swift
class NetworkClient {
    let session: URLSession
    init(session: URLSession = .shared)

    /// baseUrl + path + query → URL 문자열.
    /// nil 값 항목은 제외하고, '+'는 %2B로 강제 인코딩한다(Go가 '+'를 공백으로 해석).
    func makeURL(path: String, query: [URLQueryItem] = []) throws -> String

    /// 인증 요청 → (Data, HTTPURLResponse). 상태 코드와 Content-Type을 검증한다.
    /// - 401이면 토큰을 리셋하고 1회 재시도한다.
    /// - 200 + text/html이면 .unsupportedEndpoint
    /// - 2xx가 아니면 바디를 ServerErrorBody로 파싱해서 .server
    func fetchData(path: String, query: [URLQueryItem] = [],
                   accept: AcceptKind) async throws -> (Data, HTTPURLResponse)

    func fetchJSON<T: Decodable>(path: String, query: [URLQueryItem] = []) async throws -> T

    /// URLSession.download(for:)로 디스크에 직접 받은 뒤 destination으로 옮긴다.
    /// 기존 파일이 있으면 교체한다. 검증 규칙은 fetchData와 같다(accept: .any).
    func download(path: String, query: [URLQueryItem] = [],
                  to destination: URL) async throws -> HTTPURLResponse

    /// 스트리밍 요청. 상태 코드가 200이 아니면 최대 64KB까지 바디를 읽어 .server로 throw한다.
    /// timeout은 URLRequest.timeoutInterval(유휴 타임아웃)로 설정한다.
    func openStream(path: String, query: [URLQueryItem] = [],
                    timeout: TimeInterval) async throws -> (URLSession.AsyncBytes, HTTPURLResponse)

    enum AcceptKind { case json, text, any }
}
```

**구현 규칙**
- 기존 `makeRequest*`의 시그니처와 동작은 바꾸지 않는다. 내부에서 `URLSession.shared`를 쓰던 부분만 `session`으로 교체한다.
- 401 재시도:
  1. `NetworkClient.resetTokenState()`
  2. `ensureValidToken()`
  3. 같은 요청을 다시 만들어 1회만 재시도한다. 그래도 401이면 throw한다.
- `makeURL`:
  1. `URLComponents(string: baseUrl + path)`에 `queryItems`를 지정한다.
  2. `percentEncodedQuery`에서 `+`를 `%2B`로 바꾼다.
  - `path` 값의 `/`는 query에서 허용되는 문자이므로 그대로 둔다.
- Content-Type 검증:
  - `.json`: `application/json`을 기대한다.
  - `.text`: `text/plain`을 기대한다.
  - `.any`: `text/html`만 거부한다.
  - 대소문자를 무시하고 `;` 앞부분만 비교한다.

### 4.3 `ServerErrorBody`

```swift
/// 서버 오류 바디 — 핸들러는 {"error"}, JWT 미들웨어는 {"status","message"} 형식
struct ServerErrorBody: Decodable {
    let error: String?
    let message: String?
    var text: String? { error ?? message }
}
```

---

## 5. 모델

```swift
// MARK: - 공통

/// NAS 로그 경로 키 (사용자 로그 / Backend 로그 공용)
enum NasLogBase: String, CaseIterable, Identifiable, Codable, Hashable {
    case svrWasTest    = "svr-was-test"
    case gcgfUntact    = "gcgf-untact"
    case gcgfUntactStg = "gcgf-untact-stg"
    var id: String { rawValue }
    var title: String { rawValue }
}

// MARK: - 서버 로그

enum ServerLogKind: String, CaseIterable, Identifiable, Hashable {
    case backend, oauthResource, oauthAuth, mobileid
    var id: String { rawValue }
    var pathPrefix: String   // "/admin/log/backend", "/admin/log/oauth/resource", "/admin/log/oauth/auth", "/admin/log/mobileid"
    var title: String        // "Backend", "OAuth Resource", "OAuth Auth", "MobileID"
    var systemImage: String
    var supportsBase: Bool { self == .backend }
    static let defaultBase: NasLogBase = .svrWasTest
}

struct LogEntry: Codable, Hashable, Identifiable {
    let name: String
    let size: Int64
    let modTime: Int64              // Unix 초
    var id: String { name }
    var modDate: Date { Date(timeIntervalSince1970: TimeInterval(modTime)) }
    var isGzip: Bool { name.lowercased().hasSuffix(".gz") }
}

struct LogFolderListResponse: Codable { let base: String; let folders: [LogEntry] }
struct LogFileListResponse: Codable { let base: String; let folder: String; let files: [LogEntry] }

/// macOS 선택 상태와 iOS 내비게이션 값으로 쓰는 파일 참조
struct ServerLogFileRef: Hashable {
    let kind: ServerLogKind
    let base: NasLogBase?           // backend가 아니면 nil
    let folder: String?             // nil = 루트
    let entry: LogEntry
}

// MARK: - 로그 텍스트

struct LogLine: Identifiable, Hashable {
    let id: Int                     // 단조 증가 (ScrollViewReader 앵커)
    let text: String
}

struct LogContent {
    let fileName: String
    let lines: [LogLine]            // 잘림 표식 줄은 제외
    let tailLines: Int
    let truncated: Bool
}

// MARK: - 사용자 로그

/// 입력 정규화: 앞뒤 공백 제거 → "UT"/"ut" 접두사 제거 → 숫자만 남았는지 확인 → Int > 0
struct UserLogNumber: Hashable {
    let value: Int
    init?(_ raw: String)
    var fileName: String { String(format: "UT%011d.log", value) }
}

struct UserLogTarget: Hashable {
    let number: UserLogNumber
    let base: NasLogBase?           // nil = 자동
    let initialLines: Int           // 100/200/500/1000
    let requestedAt: Date           // 같은 대상을 다시 시작할 때 .task(id:)가 재실행되도록
}

// MARK: - 업로드

struct UploadEntry: Codable, Hashable, Identifiable {
    let name: String
    let isDir: Bool
    let size: Int64
    let modTime: Int64
    var id: String { name }
    var modDate: Date { … }
    var fileKind: FileKind { … }    // 확장자로 판별: .folder/.image/.pdf/.text/.video/.archive/.other
}

struct UploadListResponse: Codable { let base: String; let path: String; let entries: [UploadEntry] }

/// "/"로 연결한 상대 경로 값 타입
struct UploadPath: Hashable {
    let segments: [String]
    static let root = UploadPath(segments: [])
    var string: String { segments.joined(separator: "/") }
    func appending(_ name: String) -> UploadPath
    var parent: UploadPath?
}

struct UploadEntryRef: Hashable {
    let directory: UploadPath
    let entry: UploadEntry
    var path: UploadPath { directory.appending(entry.name) }
}
```

---

## 6. 서비스

모든 메서드는 `async throws`이다(D2). 오류는 `logger.error("<method> 실패: \(error)")`로 남기고 다시 throw한다. **로그 본문은 로깅하지 않는다.**

### 6.1 `UserLogService` (수정)

```swift
struct UserLogService {
    /// 기존 메서드 — base 파라미터를 추가하고, 저장 로직은 DownloadStore로 교체
    func downloadUserLog(_ sno: String, base: NasLogBase? = nil) async throws -> URL

    /// 실시간 tail. 줄 단위 AsyncThrowingStream과 서버가 알려준 파일명을 반환한다.
    func openTail(number: UserLogNumber, lines: Int, base: NasLogBase?)
        async throws -> (fileName: String?, lines: AsyncThrowingStream<String, Error>)
}
```

`openTail` 동작:
1. `client.openStream(path: "/admin/getUserLogTail/\(n)", query: [lines, base], timeout: 3600)`.
2. `X-User-Log-File` 헤더를 읽는다.
3. `AsyncThrowingStream`을 만든다. 생산자는 `Task.detached`에서 바이트를 순회하며 `LineSplitter`에 넣고, 완성된 줄을 yield한다. 스트림이 끝나면 남은 부분 줄을 flush해서 yield한다.
4. 스트림이 종료(`onTermination`)되면 생산자 Task를 취소한다. 이때 URLSession 요청도 함께 취소된다.

`follow`는 항상 true로 보낸다(생략). `downloadUserLog`의 기존 호출부(iOS ErrorList 카드, macOS ErrorSidebar, UserRow)는 시그니처가 호환되므로 수정할 필요가 없다.

### 6.2 `ServerLogService` (신규)

```swift
struct ServerLogService {
    let client: NetworkClient
    func fetchFolders(kind: ServerLogKind, base: NasLogBase?) async throws -> LogFolderListResponse
    func fetchFiles(kind: ServerLogKind, base: NasLogBase?, folder: String?) async throws -> LogFileListResponse
    func fetchContent(_ ref: ServerLogFileRef, tail: Int) async throws -> LogContent
    func download(_ ref: ServerLogFileRef) async throws -> URL      // DownloadStore 경로 반환
}
```

- query 구성:
  - `base`는 `kind.supportsBase`일 때만 넣는다.
  - `folder`는 nil이나 빈 값이면 넣지 않는다.
- `fetchContent`:
  1. `fetchData(accept: .text)`로 받는다.
  2. 헤더를 파싱한다(`X-Log-File`, `X-Log-Tail-Lines`, `X-Log-Truncated`).
  3. 본문을 UTF-8로 디코딩한다. 손실 디코딩을 허용한다.
  4. `\n`으로 나누고 마지막 빈 원소를 제거한다.
  5. truncated이고 첫 줄이 `... (앞부분 생략`으로 시작하면 그 줄을 제거한다.
  6. `LogLine(id: index)`로 변환한다.
  - 분할은 `Task.detached`에서 수행한다. 10,000줄 기준으로 메인 스레드를 막지 않기 위해서다.

### 6.3 `UploadService` (신규)

```swift
struct UploadService {
    let client: NetworkClient
    func list(_ path: UploadPath) async throws -> UploadListResponse
    /// 캐시를 먼저 확인한다. 같은 크기와 수정 시각의 파일이 있으면 재사용하고, 없으면 내려받는다.
    func fetchFile(_ ref: UploadEntryRef) async throws -> URL
}
```

- 캐시 경로는 `DownloadStore.cacheURL(category: .upload, relativePath: ref.path.string)`로, 서버 경로 구조를 그대로 미러링한다.
- 받은 뒤 파일의 `modificationDate`를 `entry.modDate`로 설정한다. 다음 조회 때 `fileSize == entry.size && modificationDate == entry.modDate`이면 재사용한다.
- 저장할 파일 이름에는 응답 헤더 대신 **목록의 `entry.name`**을 쓴다. 헤더의 filename은 RFC 5987 인코딩이 아니기 때문이다.

---

## 7. 기능별 상세 설계

### 7.1 F1 — 사용자 로그 실시간 보기

#### 상태 모델

```swift
@MainActor
final class UserLogTailModel: ObservableObject {
    enum Status: Equatable {
        case idle                       // 시작 전
        case connecting
        case streaming                  // 첫 응답 헤더 수신 이후
        case stopped(reason: StopReason)  // .user / .background / .ended(서버가 스트림 종료)
        case failed(message: String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var lines: [LogLine] = []
    @Published private(set) var fileName: String?
    @Published private(set) var droppedLineCount = 0     // 상한 초과로 버린 줄 수
    @Published private(set) var lastReceivedAt: Date?
    @Published var follow = true                          // 하단 따라가기

    let maxLines = 5_000
    private let flushInterval: Duration = .milliseconds(150)

    func start(_ target: UserLogTarget)    // 진행 중인 스트림이 있으면 취소한 뒤 버퍼를 비우고 시작
    func stop(reason: StopReason = .user)
    func reconnect()                       // 마지막 target으로 start
    func clear()                           // 버퍼만 비움
    func snapshotFile() throws -> URL      // 현재 버퍼를 임시 .log로 저장(공유용)
}
```

#### 수신 파이프라인

```
URLSession.AsyncBytes ─(detached Task)─▶ LineSplitter ─▶ PendingLines(lock 보호 배열)
                                                              │
                         MainActor flush 루프(150ms) ◀────────┘
                              │ drain → lines에 append → 5,000줄 초과분 앞에서 제거
                              ▼
                         @Published lines → LogLinesView
```

- `PendingLines`: `OSAllocatedUnfairLock<[String]>`으로 감싼 버퍼. 생산자는 append, flush 루프는 swap-out한다.
- flush 루프는 `start` 시점에 MainActor Task로 시작한다. `while !Task.isCancelled { try await Task.sleep(for: flushInterval); drain() }`.
- 상한 처리: `lines.count > maxLines`이면 `removeFirst(excess)`를 하고 `droppedLineCount += excess`.
- 줄 id는 모델이 관리하는 단조 증가 카운터로 매긴다.

#### 수명주기

| 이벤트 | 동작 |
|---|---|
| 화면 진입 / `target` 변경 | `.task(id: target) { model.start(target) }`. 이전 Task는 자동으로 취소된다 |
| 화면 이탈 | `.task` 취소 → `onDisappear`에서 `model.stop(reason: .user)` |
| iOS `scenePhase != .active` | streaming 중이면 `stop(reason: .background)` |
| iOS `scenePhase == .active` | 상태가 `.stopped(.background)`이면 `reconnect()` |
| 서버 스트림 정상 종료 | `.stopped(.ended)`. "재연결" 버튼을 표시한다 |
| 네트워크 오류 / 타임아웃 | `.failed(message)`. "재연결" 버튼을 표시한다 |

재연결하면 **버퍼를 비우고 다시 시작한다.** 초기 N줄을 다시 받기 때문에, 버퍼를 유지하면 중복이 생긴다.

#### UI

- **입력 폼(`UserLogForm`)**
  - 사용자 번호 `TextField`: iOS는 `.keyboardType(.numberPad)` 대신 `.asciiCapable`을 쓴다. `UT` 접두사를 붙여넣을 수 있게 하기 위해서다.
  - 파일명 미리보기 캡션: `UT00000109114.log`.
  - `LogBasePicker(selection: NasLogBase?, allowsAuto: true)`.
  - 초기 줄 수 Picker: 100 / 200 / 500 / 1000.
  - 버튼: [시작] [전체 다운로드]. 번호가 유효하지 않으면 비활성화한다.
- **상태 바:** 상태 아이콘과 문구(대기 / 연결 중… / 수신 중 / 중지됨 / 오류), 파일명, "마지막 수신 n초 전"(`TimelineView(.periodic(by: 1))`), 생략된 줄 수 배지.
- **툴바:** [중지 / 재연결] [따라가기 토글] [검색] [줄바꿈 토글] [지우기] [더보기: 전체 복사, 버퍼 공유(ShareLink)].
- **본문:** `LogLinesView`(§8.1).
- **플랫폼 배치:**
  - **iOS `UserLogViewForIOS`:** 한 화면이다. 위쪽에 폼(`DisclosureGroup`. 시작하면 자동으로 접힌다), 아래에 상태 바와 뷰어.
  - **macOS:**
    - 콘텐츠 컬럼 `UserLogSidebar`: 폼과 최근 번호 목록(P2)을 둔다. [시작]을 누르면 `nav.userLogTarget = UserLogTarget(...)`.
    - 디테일 컬럼 `UserLogTailView(target:)`: target이 없으면 `EmptyStateView("사용자 번호를 입력하고 시작하세요")`.

#### 전체 다운로드 (F1-11)

- `downloadUserLog(sno, base:)`로 받은 뒤 처리 방식은 플랫폼마다 다르다.
  - iOS: `DownloadedFileActions`를 표시한다([미리보기] [공유]).
  - macOS: `~/Downloads`에 저장하고 [열기] [Finder에서 보기]를 표시한다.
- 실패하면 상태 영역에 오류를 표시한다. 기존처럼 조용히 무시하지 않는다.

#### 오류 상세에서 진입 (F1-13, P2)

- `ErrorCloudItemView`의 `UserRow`에 "실시간 로그" 액션을 추가한다.
  - iOS: `NavigationLink`로 `UserLogViewForIOS(initialNumber:)`를 연다.
  - macOS: `nav.selectedSidebarItem = .userLogTail`과 `nav.userLogTarget = …`를 설정한다.

### 7.2 F2 — 서버 로그 뷰어

#### 화면 흐름

**iOS (홈 카드 "서버 로그")**
```
ServerLogKindListViewIOS            로그 종류 4개 + (Backend 선택 시) base Picker
  └─▶ ServerLogFolderListViewIOS    "(루트)" + 폴더 목록 · .refreshable · NAS 폴백 경고
        └─▶ ServerLogFileListViewIOS   파일 목록 · .searchable(이름 필터) · .refreshable
              └─▶ ServerLogContentView   tail Picker · 다시 읽기 · 검색 · 다운로드
```

**macOS**
- **콘텐츠 컬럼 `ServerLogSidebar`:**
  - 상단 컨트롤:
    - 종류 `Picker`(`.menu`)
    - Backend일 때만 base `Picker`
    - 폴더 `Picker`: "(루트)"와 folders, 기본값은 루트
  - 본문: 파일 `List(selection: $nav.selectedServerLogFile)`.
  - 툴바: 새로고침. `.searchable`을 단다. `navigationSubtitle("N개")`.
  - 종류, base, 폴더 중 하나가 바뀌면 `nav.selectedServerLogFile = nil`.
- **디테일 컬럼:** `ServerLogContentView(ref:)`. ref가 없으면 `EmptyStateView`.

#### `ServerLogContentModel`

```swift
@MainActor
final class ServerLogContentModel: ObservableObject {
    @Published private(set) var phase: LoadPhase<LogContent> = .idle   // .idle/.loading/.loaded/.failed(Error)
    @Published var tail = 1_000                                        // 200/500/1000/5000/10000
    @Published private(set) var download: DownloadPhase = .idle         // .idle/.downloading/.done(URL)/.failed
    func load(_ ref: ServerLogFileRef) async
    func download(_ ref: ServerLogFileRef) async
}
```
- `.task(id: ContentKey(ref, tail))`로 불러온다. ref나 tail이 바뀌면 다시 불러온다.
- 불러오는 동안에도 이전 내용을 유지하고, 상단에 `ProgressView`를 겹쳐 보여준다. 깜빡임을 막기 위해서다.
- 상단 정보 줄: 파일명, 크기, 수정 시각. truncated이면 "최근 N줄만 표시" 배지를 붙인다.
- `.gz`이면 "압축 해제하여 표시" 캡션을 붙인다. 다운로드한 파일을 iOS에서 미리볼 수 없으므로 [공유]만 제공한다.

#### 목록 화면 공통

- 행 컴포넌트는 `FileEntryRow`(§8.4)를 쓴다.
- 빈 목록은 `EmptyStateView`로 표시한다. 오류는 `OpsErrorView`로 표시하며 [다시 시도] 버튼을 둔다.
- NAS 폴백 경고(F2-10): 응답의 `base`가 `/mnt/nas/`로 시작하지 않으면 목록 위에 주황색 배너를 띄운다. 문구는 "NAS가 마운트되지 않아 로컬 경로를 표시 중입니다: {base}".
- 마지막으로 선택한 kind와 base는 `@AppStorage("serverLog.kind")`, `@AppStorage("serverLog.base")`로 기억한다(F2-12).

### 7.3 F3 — 업로드 브라우저

#### `UploadBrowserModel`

```swift
@MainActor
final class UploadBrowserModel: ObservableObject {
    @Published private(set) var path: UploadPath
    @Published private(set) var phase: LoadPhase<UploadListResponse> = .idle
    @Published var filter = ""
    @Published var sort: UploadSort = .server             // .server/.name/.size/.modified
    @Published var ascending = false
    var visibleEntries: [UploadEntry]                    // 필터 → 정렬(디렉터리 우선 유지)
    func load() async
    func open(_ dir: UploadEntry)                        // macOS: path 변경 후 load
    func goUp()                                          // macOS
    func go(to path: UploadPath)                         // macOS 브레드크럼
}
```

- 이름 정렬은 `localizedStandardCompare`를 쓴다. 한글이 자연스럽게 정렬된다.
- `.server`는 서버 순서를 그대로 쓴다.

#### 파일 열기

| 단계 | 동작 |
|---|---|
| 1 | 크기가 50MB를 넘으면 `confirmationDialog("{크기} 파일을 내려받을까요?")` |
| 2 | `UploadService.fetchFile`. 진행 중에는 행에 `ProgressView`를 표시하고, 취소하면 Task를 취소한다 |
| 3 | 완료되면 `previewURL = url` → `.quickLookPreview($previewURL)` |
| 4 | 실패하면 행 아래 또는 디테일에 오류를 표시한다 |

#### 플랫폼 배치

- **iOS `UploadBrowserViewIOS(path:)`**
  - 재귀 구조다. 디렉터리 행은 `NavigationLink { UploadBrowserViewIOS(path: path.appending(name)) }`로 연다.
  - 파일 행은 탭하면 위의 열기 동작을 한다.
  - 내비게이션 타이틀은 마지막 세그먼트, 루트이면 "업로드".
  - `.searchable`, 툴바에 정렬 `Menu`, `.refreshable`.
  - Quick Look 화면 자체에 공유 버튼이 있으므로 별도 공유 UI가 필요 없다.
- **macOS**
  - 콘텐츠 컬럼 `UploadBrowserSidebar`:
    - 상단에 브레드크럼(`업로드 › app › 20251205_105727`. 각 세그먼트는 Button)과 [상위] 버튼.
    - 디렉터리 행은 클릭하면 이동하는 Button이다. 파일 행은 `List(selection: $nav.selectedUploadEntry)`로 선택한다.
  - 디테일 컬럼 `UploadFileDetailView(ref:)`:
    - `InfoRow`로 이름, 경로, 크기, 수정 시각, 종류를 표시한다.
    - 버튼: [Quick Look] [다운로드 폴더에 저장] [Finder에서 보기(저장 후)].
    - P2: 이미지는 디테일 안에 인라인으로 미리보기한다.

---

## 8. 공통 UI 컴포넌트

### 8.1 `LogLinesView`

```swift
struct LogLinesView: View {
    let lines: [LogLine]
    var searchQuery: String = ""
    var currentMatchID: LogLine.ID? = nil      // 검색 이동 대상
    var wrap: Bool = true
    var showLineNumbers: Bool = false
    @Binding var follow: Bool                   // tail일 때만 의미 있음, 정적 뷰어는 .constant(false)
}
```

- `ScrollViewReader`와 `ScrollView`를 쓴다. `wrap == false`이면 `[.vertical, .horizontal]`로 스크롤한다.
- 줄은 `LazyVStack(alignment: .leading, spacing: 0)`에 `ForEach(lines)`로 그린다.
- 각 줄은 `Text`이며 `AppFont.mono`와 `.textSelection(.enabled)`를 적용한다.
- 검색어가 들어 있는 줄만 `AttributedString`으로 하이라이트한다. 나머지는 일반 `Text`로 그린다(성능).
- 따라가기:
  - `onChange(of: lines.last?.id)`에서 `follow`이면 `proxy.scrollTo(lastID, anchor: .bottom)`.
  - 사용자가 위로 스크롤하면 `follow`를 끈다. `.scrollPosition(id:anchor: .bottom)`(iOS 17/macOS 14)로 하단 가시 id를 추적해서, 마지막 id가 아니면 false로 바꾼다.
- 행 컨텍스트 메뉴에 "이 줄 복사"(`Util.copyToClipboard`)를 둔다.
- 기존 `TraceDetailView`는 렌더링할 때마다 전체 텍스트를 다시 나눈다. 그래서 재사용하지 않고, 검색 UI 아이디어만 가져온다.

### 8.2 `LogSearchBar`

- 입력 필드, "n/m" 표시, 이전/다음 버튼, 대소문자 무시.
- 일치 목록은 검색어가 바뀌면 250ms debounce 후에 다시 계산한다.
- tail 모드에서 새 줄이 들어오면, 새로 붙은 줄만 추가로 검사한다.

### 8.3 `LogBasePicker`

`Picker` 하나이며, `allowsAuto`가 true이면 맨 앞에 "자동"(nil)을 붙인다. iOS는 `.menu`, macOS는 `.menu` 스타일을 쓴다.

### 8.4 `FileEntryRow`

아이콘, 이름(한 줄, 중간 생략), 보조 줄("12.3 MB · 2026-10-31 23:59")로 구성한다. 크기는 `Util.formatFileSize`(`ByteCountFormatter`, `.file`), 시각은 `Util.formatUnixTime`(`yyyy-MM-dd HH:mm`)으로 표시한다.

| FileKind | SF Symbol |
|---|---|
| folder | `folder.fill` |
| image | `photo` |
| pdf | `doc.richtext` |
| text/log | `doc.text` |
| archive(.gz/.zip) | `doc.zipper` |
| video | `film` |
| other | `doc` |

### 8.5 `OpsErrorView`와 메시지 매핑

| 오류 | 제목 | 설명 | 아이콘 |
|---|---|---|---|
| `.unsupportedEndpoint` | 지원하지 않는 서버 | 현재 연결된 서버에 이 기능이 없습니다. 환경 설정을 확인하세요 | `exclamationmark.icloud` |
| `.server(404, …)` | 찾을 수 없음 | 서버 메시지(예: Log file not found). 사용자 로그이면 "번호와 경로(base)를 확인하세요"를 덧붙인다 | `questionmark.folder` |
| `.server(401, …)` (재시도 후에도) | 인증 실패 | 서버 메시지 | `lock.slash` |
| `.server(400, …)` | 잘못된 요청 | 서버 메시지 | `exclamationmark.triangle` |
| `.server(500, …)` | 서버 오류 | 서버 메시지. 경로가 들어 있을 수 있다 | `xmark.octagon` |
| `URLError.timedOut` / `.notConnectedToInternet` 등 | 연결 실패 | `localizedDescription` | `wifi.exclamationmark` |
| 그 외 | 오류 | `localizedDescription` | `exclamationmark.triangle` |

`OpsErrorView(error:retry:)`는 `EmptyStateView`와 같은 레이아웃을 쓰며, [다시 시도] 버튼을 추가한다.

### 8.6 `DownloadedFileActions`

다운로드가 끝난 `URL`을 받아 플랫폼별 버튼을 보여준다.

| 플랫폼 | 버튼 |
|---|---|
| iOS | [미리보기](`.quickLookPreview`, `.gz`이면 숨김) · [공유](`ShareLink(item:)`) |
| macOS | [열기](`NSWorkspace.shared.open`) · [Finder에서 보기](`NSWorkspace.shared.activateFileViewerSelecting`) |

---

## 9. 파일 저장 정책 — `DownloadStore`

```swift
enum DownloadStore {
    enum Category: String { case userLog, serverLog, upload }
    /// 사용자가 명시적으로 '다운로드'한 파일의 저장 위치
    static func downloadURL(category: Category, fileName: String) throws -> URL
    /// 미리보기용 캐시 위치 (업로드 미러)
    static func cacheURL(category: Category, relativePath: String) throws -> URL
    /// 앱 시작 시 호출 — Caches/Ops 아래에서 24시간 지난 파일 삭제
    static func purgeExpired(olderThan: TimeInterval = 86_400)
}
```

| 구분 | iOS | macOS |
|---|---|---|
| 로그 다운로드 (`downloadURL`) | `Caches/Ops/<category>/<fileName>`. 덮어쓴다 | `~/Downloads/<fileName>`. 이름이 겹치면 `name (1).ext` 식으로 번호를 붙인다 |
| 업로드 미리보기 (`cacheURL`) | `Caches/Ops/upload/<relativePath>` | 같음 |
| macOS "다운로드 폴더에 저장" | — | 캐시 파일을 `~/Downloads`로 복사한다(번호 규칙 동일) |
| 정리 | 앱을 시작할 때 `purgeExpired()` | 같음(Caches만, ~/Downloads는 건드리지 않는다) |

- 기존 `UserLogService.downloadUserLog`의 iOS 저장 위치(Documents)도 `downloadURL(category: .userLog)`로 바꾼다. Documents는 "파일" 앱에 노출되지 않으면서 백업 대상이기만 해서 적절하지 않다.
- macOS 샌드박스는 `ENABLE_FILE_ACCESS_DOWNLOADS_FOLDER = readwrite`가 이미 설정되어 있다. 엔타이틀먼트를 바꿀 필요가 없다.
- `purgeExpired()`는 `MobileAdminApp`의 init 또는 첫 scene `.task`에서 백그라운드 우선순위로 호출한다.

---

## 10. 내비게이션 연결

### 10.1 공통 — `SlidebarItem` (`views/macos/SlidebarViewForMac.swift`)

| case | title | img |
|---|---|---|
| `userLogTail` | 사용자 로그 | `person.text.rectangle` |
| `serverLog` | 서버 로그 | `doc.text.magnifyingglass` |
| `uploadBrowser` | 업로드 파일 | `folder` |

- `groups`에 `("운영", [.userLogTail, .serverLog, .uploadBrowser])`를 추가한다. `groupIcons["운영"] = "server.rack"`.
- 수기로 관리하는 `allCases`에도 추가한다.

### 10.2 macOS

| 파일 | 변경 |
|---|---|
| `model/NavigationState.swift` | `@Published var userLogTarget: UserLogTarget?`, `selectedServerLogFile: ServerLogFileRef?`, `selectedUploadEntry: UploadEntryRef?` |
| `views/macos/ContentListViewForMac.swift` `makeSidebar` | 새 case 3개를 각 `*Sidebar`에 연결 |
| `views/macos/DetailViewForMac.swift` `detailContent` | 새 case 3개를 각각 `UserLogTailView` / `ServerLogContentView` / `UploadFileDetailView`에 연결하고, 선택이 없을 때는 `EmptyStateView`를 표시 |
| 사이드바 항목 전환 | 선택 상태 3개를 nil로 초기화한다(다른 카테고리의 선택 해제 방식과 동일) |

### 10.3 iOS

| 파일 | 변경 |
|---|---|
| `views/ios/HomeViewForIOS.swift` | `menuItems`에 튜플 3개, `destinationView`에 case 3개를 추가한다 |
| 새 화면 | `UserLogViewForIOS`, `ServerLogKindListViewIOS`, `UploadBrowserViewIOS(path: .root)` |
| `Scense/MySceneForIOS.swift` | 변경하지 않는다(탭은 4개를 유지한다. PRD Q5) |

---

## 11. 비기능 · 성능 · 보안

| 항목 | 기준 / 방법 |
|---|---|
| tail UI 갱신 | 150ms 배치. 1,000줄이 한 번에 와도 `lines`에 한 번만 append한다 |
| tail 메모리 | 최대 5,000줄. 한 줄 평균 200B라면 1MB 정도 |
| content 렌더링 | 최대 10,000줄. 분할은 백그라운드에서 하고, 렌더링은 LazyVStack으로 한다 |
| 파일 다운로드 | `URLSession.download(for:)`로 디스크에 바로 쓴다. 메모리에 올리지 않는다 |
| 최대 줄 길이 | `LineSplitter`는 한 줄이 1MiB를 넘으면 강제로 끊어서 내보낸다. 서버 Scanner 제한과 같은 값이다 |
| 타임아웃 | tail은 3,600초(유휴). 그 외 요청은 기본 60초. content 요청은 큰 `.gz` 처리 시간을 고려해 120초 |
| 개인정보 | 로그 본문과 업로드 파일 내용을 `Logger`에 출력하지 않는다. URL과 상태 코드만 기록한다 |
| 캐시 수명 | Caches/Ops 아래 파일은 24시간이 지나면 삭제한다 |
| 접근 통제 | 기존 iOS 생체 인증 게이트를 그대로 쓴다. 기능별 추가 인증은 하지 않는다 |
| 동시성 | 상태 모델은 `@MainActor`. 바이트 순회와 텍스트 분할은 `Task.detached`. Swift 5 언어 모드에서 경고가 나지 않게 `Sendable`을 고려한다 |

---

## 12. 서버 측 개선 제안 (범위 외, 참고)

v1은 서버를 바꾸지 않는다고 전제한다. 다만 아래 항목은 서버에서 해결하면 클라이언트가 단순해진다.

1. `/admin/*` 아래의 존재하지 않는 경로에 SPA HTML 대신 JSON 404를 반환한다(`NoRoute`에서 prefix로 분기).
2. tail 스트림에 heartbeat(예: 15초마다 빈 주석 줄 또는 SSE)를 넣는다. 그러면 클라이언트가 유휴 타임아웃을 짧게 잡을 수 있다.
3. tail에서 로그 로테이션을 감지한다(inode 변경 시 재오픈).
4. `Content-Disposition`에 RFC 5987 `filename*=UTF-8''…`를 추가한다.
5. `upload/file`에 GET과 쿼리 토큰을 지원한다. 그러면 AVPlayer로 바로 스트리밍 재생할 수 있다.

---

## 13. 테스트 전략

> 현재 `MobileAdminTests/`는 어느 타깃에도 연결되어 있지 않다. 테스트 타깃을 복구하는 작업이 선행되어야 한다(tasks T0.1).

### 13.1 단위 테스트 (Swift Testing)

| 대상 | 케이스 |
|---|---|
| `LineSplitter` | `\n` / `\r\n` 처리, 청크 경계에서 끊긴 줄, **UTF-8 멀티바이트가 청크 경계에서 쪼개진 경우**, 연속 빈 줄 보존, flush 시 남은 부분 줄, 1MiB 초과 줄 강제 분할 |
| `NetworkClient.makeURL` | `+`가 `%2B`로 바뀌는지, 한글과 공백 인코딩, `path=a/b` 유지, nil 항목 제외, query 순서 보존 |
| 응답 검증 | 200 + `text/html`이면 `unsupportedEndpoint`, 404 `{"error"}` 파싱, 401 `{"message"}` 파싱, 바디가 비었을 때 |
| 모델 디코딩 | §2 샘플 JSON 전체, `modTime`의 Date 변환 |
| `UserLogNumber` | `"109114"`, `"UT00000109114"`, `" ut12 "`, `"0"`, `"-1"`, `"12a"`, 빈 문자열, `fileName` 형식 |
| `ServerLogService` content 파싱 | truncated 표식 줄 제거, 표식 없는 truncated, 마지막 개행 처리 |
| `UploadPath` | `appending`, `parent`, `string`, 루트 |
| `UploadBrowserModel.visibleEntries` | 필터, 정렬별 디렉터리 우선 유지, 한글 정렬 |
| `DownloadStore` | macOS 중복 이름 번호 붙이기, `purgeExpired` 기준 시각 |
| `UserLogTailModel` | 상한 초과 시 `droppedLineCount`, 재시작 시 버퍼 초기화, 상태 전이 |

### 13.2 통합 테스트 (URLProtocol 스텁)

`NetworkClient(session:)`에 `URLProtocol` 하위 클래스를 등록한 세션을 주입한다.
- 401을 한 번 받은 뒤 200이면 성공하고, 토큰 재발급 요청이 1회 일어났는지 확인한다.
- tail: 청크 여러 개로 나뉜 응답이 줄 단위로 바르게 조립되는지, `X-User-Log-File`을 읽는지 확인한다.
- download: 파일이 저장되는지, 저장된 이름이 목록의 이름과 같은지 확인한다.

### 13.3 수동 QA 체크리스트

tasks.md의 T4.4를 참고한다.

---

## 14. 구현 메모 — 계획 대비 변경 사항

| 항목 | 계획 | 구현 | 이유 |
|---|---|---|---|
| 서비스 소유 | 상태 모델이 서비스를 직접 생성 | `OpsServices`(공유 `NetworkClient` 1개 + 서비스 3개)를 기본값으로 주입 | 화면마다 클라이언트를 만들지 않도록 하면서 테스트 주입은 유지 |
| 로딩 상태 | `LoadPhase<T>` enum | 모델별 `value / isLoading / error` 프로퍼티 | 다시 읽는 동안 이전 내용을 유지해야 해서 단일 enum보다 단순 |
| tail 버퍼 lock | `OSAllocatedUnfairLock` | `NSLock` (`PendingLines`) | 의존 없이 단순. 경합이 거의 없는 구간 |
| tail Task 정리 | `onDisappear`에서 stop | + `deinit`에서 취소 (`TaskHandles`) | `stop()` 없이 모델이 해제돼도 연결이 남지 않게 |
| 업로드 캐시 유효성 | 파일 `modificationDate`를 서버 `modTime`으로 설정해 비교 | 캐시 경로에 `<modTime>-<size>/` 디렉터리 포함 | 수정 시각을 서버 값으로 바꾸면 24시간 정리 기준(다운로드 시각)이 깨짐 |
| macOS 사용자 로그 다운로드 | 기존: `~/Downloads/UT….log` 덮어쓰기 | 이름 중복 시 `UT… (1).log` | 사용자 파일 덮어쓰기 방지 |
| 로그 뷰어 초기 위치 | 따라가기일 때만 하단 | `.defaultScrollAnchor(.bottomLeading)`로 항상 최근 줄부터 | 서버 로그 내용도 최근 줄 확인이 주목적 |
| iOS 서버 로그 내용 새로고침 | 당겨서 새로고침 | [다시 읽기] 버튼 | 내부 ScrollView(LogLinesView)와 refreshable 중첩 회피 |
| `UserRow` 실시간 로그 진입(F1-13, P2) | Phase 4 | v1에 포함 | 변경 범위가 작음 |
| `LogContent.parse` 줄 분할 | `split(separator: "\n")` | `"\n"` 또는 `"\r\n"` Character로 분할 | Swift에서 `"\r\n"`은 하나의 Character라 CRLF 로그가 한 줄로 합쳐지는 버그를 테스트로 발견 |
| 테스트 직렬화 | — | `SharedTokenStateTests` 상위 suite 아래에 `NetworkClientTests`, `OpsNetworkTests` | 둘 다 `NetworkClient` static 토큰을 다뤄 병렬 실행 시 경합 |
