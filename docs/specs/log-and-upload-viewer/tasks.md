# Tasks — 로그 · 업로드 파일 뷰어

| 항목 | 내용 |
|---|---|
| 문서 상태 | 진행 중 — 구현 완료, Xcode 빌드·테스트 타깃·실기기 QA 남음 |
| 작성일 | 2026-11-01 |
| 관련 문서 | [prd.md](./prd.md) · [spec.md](./spec.md) |

**크기:**
- **S**: 반나절 이하
- **M**: 1일 안팎
- **L**: 2일 이상

**표기:** `→`는 선행 작업, `§`는 spec 절 번호를 뜻한다.

---

## 진행 현황 (2026-11-01)

| 구분 | 상태 |
|---|---|
| Phase 0 ~ 3 (T0.2 ~ T3.4) | 구현 완료 |
| T4.1 오류 상세 → 실시간 로그 | 구현 완료 (P2를 앞당김) |
| T4.3 문서 갱신 | CLAUDE.md 구조 갱신, spec §14 변경 사항 기록 |
| T0.1 테스트 타깃 복구 | **미진행** — Xcode GUI 작업 필요 (아래 절차) |
| T4.2 P2 편의 기능 | 미진행 |
| T4.4 수동 QA | 미진행 — Xcode 빌드 후 실기기에서 |

**검증 방법 (작업 환경에 Xcode가 없어 대체)**
- macOS 대상 `swiftc -typecheck` 전체 통과, iOS 분기는 Mac Catalyst 대상 타입체크로 통과
  - SwiftData(`@Model`/`@Query`) 사용 파일 4개(`MobileAdminApp`, `MySceneForIOS/MacOS`, `EnvSetView`)는 매크로 플러그인 부재로 제외 — 이 중 `MobileAdminApp.swift`에 `init()` 3줄 추가됨
- SwiftPM 하네스로 단위 테스트 실행: 239개 중 238개 통과
  - 실패 1건 `UtilTests.combineTodayWithTime_emptyString_returnsNil`은 **기존 코드(`Util.combineTodayWithTime`, 미수정) 문제**로 이번 변경과 무관
  - `EnvironmentConfigTests`(SwiftData), `MobileAdminTests`(라이브 서버)는 하네스에서 제외

**Xcode에서 남은 확인**
1. iOS / macOS 빌드 (새 파일은 synchronized group이라 자동 포함)
2. T0.1 테스트 타깃 복구 후 `MobileAdminTests` 실행
3. T4.4 수동 QA

## 공통 완료 기준 (모든 태스크)

- [ ] iOS 시뮬레이터 빌드와 macOS 빌드가 모두 성공한다.
  ```bash
  xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' build
  xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=macOS' build
  ```
- [x] 해당 태스크의 단위 테스트를 추가했고 통과한다(T0.1 이후). — SwiftPM 하네스로 실행, 신규 테스트 전부 통과
- [x] UI 문자열과 주석은 한국어로 쓴다. 긴 파일에는 `// MARK: -`로 구역을 나눈다.
- [x] 로그 본문과 파일 내용을 `Logger`에 출력하지 않는다.
- [x] macOS 전용 API는 `#if os(macOS)`로 감싼다(단일 멀티플랫폼 타깃이므로).

## PR 분할 제안

| PR | 포함 태스크 | 리뷰 포인트 |
|---|---|---|
| #1 기반 | T0.1 ~ T0.9 | 네트워킹 확장이 기존 호출에 회귀를 일으키지 않는지, 공통 뷰의 API |
| #2 서버 로그 | T1.1 ~ T1.5 | 뷰어 성능, 플랫폼별 흐름 |
| #3 사용자 로그 tail | T2.1 ~ T2.6 | 스트림 수명주기, 취소, 메모리 상한 |
| #4 업로드 브라우저 | T3.1 ~ T3.4 | 캐시, Quick Look, 한글/특수문자 경로 |
| #5 마무리 | T4.1 ~ T4.4 | P2 기능, 문서 |

## 의존 관계

```
T0.1 ─────────────────────────────────────────────▶ (모든 테스트 작업)
T0.2 ─▶ T0.3 ─┬─▶ T1.1 ─▶ T1.2 ─┬─▶ T1.3
T0.4 ─────────┤                  └─▶ T1.4 ─▶ T1.5
T0.5 ─────────┼─▶ T2.1 ─▶ T2.2 ─▶ T2.3 ─┬─▶ T2.4
T0.6 ─┐       │                         └─▶ T2.5 ─▶ T2.6
T0.7 ─┼───────┴─▶ T3.1 ─▶ T3.2 ─┬─▶ T3.3
T0.8 ─┤                          └─▶ T3.4
T0.9 ─┘                                              ─▶ T4.x
```

---

## Phase 0 — 공통 기반 (M0)

### T0.1 테스트 타깃 복구 · M · 선택(권장, PRD Q4)
- **배경:**
  - `project.pbxproj`에는 `MobileAdmin` 타깃 하나뿐이다.
  - `MobileAdminTests/`는 어느 타깃에도 연결되어 있지 않다.
  - `MobileAdmin.xctestplan`은 이미 없어진 타깃 ID를 가리킨다.
  - 스킴이 `xcuserdata`에만 있다.
- **작업:**
  - [ ] Xcode에서 Unit Testing Bundle 타깃 `MobileAdminTests`를 추가한다. Swift Testing을 쓰고, Host Application은 MobileAdmin, 폴더는 기존 `MobileAdminTests/`로 지정한다. pbxproj를 손으로 고치지 말고 Xcode GUI로 작업한다.
  - [ ] `MobileAdmin.xctestplan`의 타깃 참조를 새 타깃으로 고친다.
  - [ ] 스킴을 Shared로 바꾼다(`xcshareddata/xcschemes/MobileAdmin.xcscheme`).
  - [ ] 라이브 서버에 의존하는 기존 테스트(`MobileAdminTests.swift`)는 `.disabled` 또는 tag로 분리한다.
- **완료 기준:** `xcodebuild test -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'`에서 기존 단위 테스트가 통과한다.

### T0.2 `NetworkError` 확장 · S · §4.1, §4.3
- [x] `model/NetworkError.swift`에 `server(statusCode:message:url:)`, `unsupportedEndpoint(url:)`, `unexpectedContentType(_:url:)`을 추가하고, 각각의 한국어 `errorDescription`을 쓴다.
- [x] `model/Ops/OpsCommon.swift`에 `ServerErrorBody`(`error` / `message`)를 추가한다.
- [x] 테스트: 두 오류 형식 디코딩, `errorDescription` 문구.

### T0.3 `NetworkClient` 확장 · M · §4.2 · → T0.2
- [x] `session: URLSession` 프로퍼티와 `init(session: URLSession = .shared)`를 추가한다. 기존 `URLSession.shared` 사용처를 `session`으로 바꾼다.
- [x] `makeURL(path:query:)`: `URLComponents`를 쓰고 `+`를 `%2B`로 바꾼다.
- [x] 응답 검증 공통 함수를 만든다. 상태 코드, `text/html` 감지, 오류 바디 파싱을 한다.
- [x] `fetchData(path:query:accept:)`, `fetchJSON(path:query:)`.
- [x] `download(path:query:to:)`: `session.download(for:)`로 받고 `FileManager.replaceItemAt`로 옮긴다.
- [x] `openStream(path:query:timeout:)`: `session.bytes(for:)`를 쓴다. 상태 코드가 200이 아니면 바디를 64KB까지 읽고 throw한다.
- [x] 401 재시도: `resetTokenState()`와 `ensureValidToken()`을 호출한 뒤 1회만 재시도한다.
- [x] 테스트(URLProtocol 스텁):
  - `makeURL` 인코딩: `+`, 한글, 공백, `/`.
  - HTML이면 `unsupportedEndpoint`.
  - 404 메시지 파싱.
  - 401 한 번 뒤 성공(토큰 요청 1회).
- **완료 기준:** 기존 `makeRequest*` 호출부의 동작이 바뀌지 않는다(빌드와 기존 화면 동작을 수동으로 확인).

### T0.4 `LineSplitter` · S · D4, §11
- [x] `Util/LineSplitter.swift`: `mutating func append(_ byte: UInt8) -> String?`, `mutating func flush() -> String?`를 만든다. `\r\n`을 처리하고, 1MiB를 넘는 줄은 강제로 내보낸다.
- [x] UTF-8은 줄이 완성된 뒤에 `String(decoding:as: UTF8.self)`로 디코딩한다. 그래서 바이트 단위로 쪼개져 들어와도 멀티바이트 문자가 깨지지 않는다.
- [x] 테스트: §13.1 `LineSplitter` 케이스 전부.

### T0.5 모델 정의 · S · §5
- [x] `model/Ops/OpsCommon.swift`: `NasLogBase`.
- [x] `model/Ops/ServerLogModels.swift`: `ServerLogKind`, `LogEntry`, `LogFolderListResponse`, `LogFileListResponse`, `ServerLogFileRef`.
- [x] `model/Ops/LogText.swift`: `LogLine`, `LogContent`.
- [x] `model/Ops/UserLogTarget.swift`: `UserLogNumber`(정규화 init), `UserLogTarget`.
- [x] `model/Ops/UploadModels.swift`: `UploadEntry`(+`FileKind`), `UploadListResponse`, `UploadPath`, `UploadEntryRef`.
- [x] ~~공용 상태 enum `LoadPhase<T>`~~ → 모델별 `value / isLoading / error`로 대체 (spec §14)
- [x] 테스트: spec §2 샘플 JSON 디코딩, `UserLogNumber` 정규화, `UploadPath` 연산, `FileKind` 판별.

### T0.6 Util 보강 · S · §8.4
- [x] `Util.formatFileSize(_ bytes: Int64) -> String`. `ByteCountFormatter`를 static으로 한 번만 만들어 둔다.
- [x] `Util.formatUnixTime(_ seconds: Int64) -> String`. 형식은 `yyyy-MM-dd HH:mm`이고 static formatter를 쓴다.
- [x] 테스트: 경계값(0, 1023, 1 MB, 1 GB), 타임존 고정.

### T0.7 `DownloadStore`와 기존 사용자 로그 다운로드 이관 · M · §9 · → T0.3, T0.5
- [x] `Util/DownloadStore.swift`: `downloadURL(category:fileName:)`, `cacheURL(category:relativePath:)`, `purgeExpired(olderThan:)`, macOS 중복 이름 번호 붙이기.
- [x] `MobileAdminApp`이 시작될 때 `purgeExpired()`를 백그라운드에서 호출한다.
- [x] `UserLogService.downloadUserLog(_:base:)`:
  - `base` 파라미터를 추가한다(기본값 nil).
  - 받는 방식을 `client.download`로 바꾼다.
  - 저장 위치를 `DownloadStore.downloadURL(.userLog)`로 바꾼다.
  - `ViewModel.downloadUserLog`의 forwarding 시그니처도 같이 고친다.
- [x] 테스트: 중복 이름 규칙, purge 기준 시각.
- **완료 기준:** 기존 진입점 세 곳(iOS ErrorList 카드, macOS ErrorSidebar, UserRow)에서 다운로드가 계속 동작한다.

### T0.8 공통 UI 컴포넌트 · L · §8 · → T0.5, T0.6
- [x] `views/common/Ops/LogLinesView.swift`: LazyVStack, 줄바꿈 토글, 줄 번호, 검색 하이라이트, follow와 `.scrollPosition` 기반 자동 해제, 줄 복사 컨텍스트 메뉴.
- [x] `LogSearchBar.swift`: 250ms debounce, n/m, 이전/다음.
- [x] `LogBasePicker.swift`: `allowsAuto` 옵션.
- [x] `FileEntryRow.swift`: `FileKind` 아이콘, 크기·시각 보조 줄. `LogEntry`와 `UploadEntry`를 모두 받을 수 있게 작은 프로토콜(`FileListItem`)을 둔다.
- [x] `OpsErrorView.swift`: §8.5 매핑 함수와 뷰, [다시 시도].
- [x] `DownloadedFileActions.swift`: iOS는 미리보기·공유, macOS는 열기·Finder에서 보기.
- [ ] 모든 컴포넌트에 `#Preview`를 둔다. 샘플 1만 줄 프리뷰로 스크롤 성능을 확인한다. — 프리뷰 코드는 작성, **Xcode 미설치로 성능 확인은 미실행**
- **완료 기준:** 프리뷰에서 1만 줄 스크롤이 끊기지 않는다. 검색 하이라이트와 이동이 동작한다.

### T0.9 내비게이션 골격 · S · §10 · → T0.5
- [x] `SlidebarItem`에 `userLogTail`, `serverLog`, `uploadBrowser`를 추가한다. `title`, `img`, `allCases`, `groups`("운영"), `groupIcons`도 함께 고친다.
- [x] `NavigationState`에 `userLogTarget`, `selectedServerLogFile`, `selectedUploadEntry`를 추가하고, 사이드바 항목이 바뀔 때 nil로 초기화한다.
- [x] `ContentListViewForMac.makeSidebar`와 `DetailViewForMac.detailContent`에 플레이스홀더 case를 넣는다(`EmptyStateView`).
- [x] `HomeViewForIOS`의 `menuItems`와 `destinationView`에 항목 3개를 추가하고 플레이스홀더 뷰를 연결한다.
- **완료 기준:** 양 플랫폼에서 메뉴 3개가 보이고, 들어가면 플레이스홀더가 표시된다.

---

## Phase 1 — F2 서버 로그 뷰어 (M1)

### T1.1 `ServerLogService` · M · §6.2 · → T0.3, T0.5
- [x] `fetchFolders`, `fetchFiles`, `fetchContent`, `download`를 구현한다. `base`는 `supportsBase`일 때만 보내고, 빈 `folder`는 생략한다.
- [x] `fetchContent`:
  - 헤더 3종을 파싱한다.
  - 분할은 `Task.detached`에서 한다.
  - truncated 표식 줄을 제거한다.
  - 요청 타임아웃은 120초로 둔다.
- [x] 테스트:
  - content 파싱: 표식 있음/없음, 마지막 개행, 빈 본문.
  - query 구성: kind별 base 포함 여부, folder 생략.

### T1.2 `ServerLogContentModel`과 `ServerLogContentView` · M · §7.2 · → T1.1, T0.8
- [x] `.task(id: (ref, tail))`로 불러온다. 다시 불러올 때도 이전 내용을 유지하고 오버레이 `ProgressView`를 띄운다.
- [x] 정보 줄(파일명, 크기, 수정 시각, truncated 배지, `.gz` 캡션), tail Picker(200/500/1000/5000/10000).
- [x] 툴바: 다시 읽기, 검색, 줄바꿈, 전체 복사, 다운로드. 다운로드가 끝나면 `DownloadedFileActions`를 표시한다.
- [x] 오류는 `OpsErrorView`로 표시한다.

### T1.3 iOS 화면 · M · §7.2 · → T1.2, T0.9
- [x] `ServerLogKindListViewIOS`: 종류 4개, Backend일 때 base Picker. `@AppStorage`로 기억한다.
- [x] `ServerLogFolderListViewIOS`: "(루트)"와 폴더 목록, `.refreshable`, 빈 상태와 오류 상태.
- [x] `ServerLogFileListViewIOS`: `FileEntryRow`, `.searchable`, `.refreshable`.
- [x] 홈 카드 "서버 로그"의 플레이스홀더를 `ServerLogKindListViewIOS`로 교체한다.

### T1.4 macOS 화면 · M · §7.2 · → T1.2, T0.9
- [x] `views/macos/ServerLogSidebar.swift`: 종류·base·폴더 Picker와 파일 `List(selection: $nav.selectedServerLogFile)`, `.searchable`, 새로고침, `navigationSubtitle`. 컨트롤이 바뀌면 선택을 해제한다.
- [x] `DetailViewForMac`의 `.serverLog` case를 `ServerLogContentView`로 연결한다.

### T1.5 NAS 폴백 경고와 상태 기억 · S · F2-10, F2-12 · → T1.3, T1.4
- [x] 응답 `base`가 `/mnt/nas/`로 시작하지 않으면 경고 배너를 띄운다(폴더 목록과 파일 목록).
- [x] 마지막 kind와 base를 `@AppStorage`로 기억한다(macOS 포함).

---

## Phase 2 — F1 사용자 로그 실시간 보기 (M2)

### T2.1 `UserLogService.openTail` · M · §6.1 · → T0.3, T0.4, T0.5
- [x] `openStream`(timeout 3600)을 호출하고 `X-User-Log-File`을 읽는다.
- [x] `AsyncThrowingStream<String, Error>`를 반환한다. 생산자는 `Task.detached`에서 바이트를 순회하고 `LineSplitter`로 줄을 만든다. `onTermination`에서 생산자를 취소한다.
- [x] 기존 `normalizeUserLogNo`와 `makeUserLogFileName`을 `UserLogNumber`로 대체한다.
- [x] 테스트(URLProtocol 스텁): 청크 3개로 나뉜 응답이 줄 단위로 조립되는지, 헤더 파싱, 404 JSON이면 `.server(404)`.

### T2.2 `UserLogTailModel` · L · §7.1 · → T2.1
- [x] 상태 머신: `idle` / `connecting` / `streaming` / `stopped(.user | .background | .ended)` / `failed`.
- [x] `PendingLines`(NSLock, spec §14)와 150ms MainActor flush 루프. + `deinit` 시 Task 취소
- [x] 5,000줄 상한, `droppedLineCount`, 단조 증가 id.
- [x] `start` / `stop` / `reconnect` / `clear` / `snapshotFile()`. 재시작하면 버퍼를 비운다.
- [x] 테스트(가짜 라인 스트림 주입):
  - 상한 초과 처리.
  - 재시작 시 초기화.
  - 스트림이 끝나면 `.stopped(.ended)`, 오류가 나면 `.failed`.
  - stop을 호출하면 생산자가 취소된다.
- **참고:** 테스트하기 쉽도록 모델은 `(UserLogTarget) async throws -> (String?, AsyncThrowingStream<String, Error>)` 클로저를 주입받게 만든다. 기본값은 `UserLogService.openTail`.

### T2.3 `UserLogForm`과 `UserLogTailView` · M · §7.1 · → T2.2, T0.8
- [x] 폼:
  - 번호 입력, 파일명 미리보기.
  - `LogBasePicker(allowsAuto: true)`, 줄 수 Picker.
  - [시작] [전체 다운로드]. 번호가 유효하지 않으면 비활성화한다.
- [x] 상태 바: 아이콘·문구, 파일명, "마지막 수신 n초 전"(`TimelineView`), 생략 줄 배지.
- [x] 툴바: 중지/재연결, 따라가기, 검색, 줄바꿈, 지우기, 전체 복사, 버퍼 공유(`ShareLink`와 `snapshotFile()`).
- [x] `.task(id: target)`로 시작하고, `onDisappear`에서 stop한다.

### T2.4 iOS `UserLogViewForIOS` · S · → T2.3, T0.9
- [x] 한 화면 구성: 폼(`DisclosureGroup`. 시작하면 자동으로 접힌다), 상태 바, 뷰어.
- [x] `@Environment(\.scenePhase)` 처리: 백그라운드로 가면 stop(.background), 다시 active가 되면 reconnect.
- [x] `init(initialNumber: String? = nil)`. T4.1에서 진입할 때 쓴다.
- [x] 홈 카드 "사용자 로그"의 플레이스홀더를 교체한다.

### T2.5 macOS `UserLogSidebar`와 상세 연결 · S · → T2.3, T0.9
- [x] 콘텐츠 컬럼에 폼을 두고, [시작]을 누르면 `nav.userLogTarget = UserLogTarget(..., requestedAt: .now)`.
- [x] `DetailViewForMac`의 `.userLogTail` case를 `UserLogTailView(target:)`로 연결한다. target이 없으면 안내 `EmptyStateView`.

### T2.6 전체 다운로드 통합과 기존 UI 오류 표시 · S · F1-11 · → T0.7, T2.3
- [x] 폼의 [전체 다운로드]는 `downloadUserLog(sno, base:)`를 호출한 뒤 `DownloadedFileActions`를 표시한다.
- [x] `ErrorListViewForIOS`의 사용자 로그 다운로드 카드에서 catch 블록이 오류를 조용히 무시하던 부분을 고쳐, 화면에 표시한다(`ErrorListViewForIOS.swift` 227–229 부근).
- [x] `ErrorCloudItemView.UserRow`(macOS)의 다운로드 실패도 화면에 표시한다.

---

## Phase 3 — F3 업로드 브라우저 (M3)

### T3.1 `UploadService` · M · §6.3 · → T0.3, T0.5, T0.7
- [x] `list(_ path:)`.
- [x] `fetchFile(_ ref:)`:
  - 캐시 경로는 `DownloadStore.cacheURL(.upload, relativePath:)`.
  - 크기와 수정 시각이 같으면 재사용한다. → 캐시 경로에 `<modTime>-<size>/`를 넣는 방식으로 구현 (spec §14)
  - 파일 이름은 `entry.name`을 쓴다.
- [x] 취소를 지원한다(Task 취소가 다운로드 취소로 이어져야 한다).
- [x] 테스트: 캐시 적중과 미적중, 경로 query에 `+`와 한글이 들어간 경우.

### T3.2 `UploadBrowserModel` · S · §7.3 · → T3.1
- [x] `path`, `phase`, `filter`, `sort`, `ascending`, `visibleEntries`(디렉터리 우선 유지, `localizedStandardCompare`).
- [x] `open(dir)`, `goUp()`, `go(to:)`, `load()`.
- [x] 테스트: 필터·정렬 조합, 디렉터리 우선, 한글 정렬.

### T3.3 iOS `UploadBrowserViewIOS` · M · §7.3 · → T3.2, T0.8, T0.9
- [x] 재귀 `NavigationLink`로 디렉터리를 탐색한다. 타이틀은 마지막 세그먼트, 루트이면 "업로드".
- [x] `.searchable`, 정렬 `Menu`, `.refreshable`, 빈 상태와 오류 상태.
- [x] 파일 열기: 50MB를 넘으면 `confirmationDialog`. 받는 동안 행에 진행 표시와 취소를 두고, 끝나면 `.quickLookPreview($previewURL)`.
- [x] 홈 카드 "업로드 파일"의 플레이스홀더를 `UploadBrowserViewIOS(path: .root)`로 교체한다.

### T3.4 macOS `UploadBrowserSidebar`와 `UploadFileDetailView` · M · §7.3 · → T3.2, T0.8, T0.9
- [x] 브레드크럼(세그먼트 Button)과 [상위]. 디렉터리 행은 클릭하면 이동하고, 파일 행은 `List(selection: $nav.selectedUploadEntry)`.
- [x] `.searchable`, 정렬 `Menu`, 새로고침, `navigationSubtitle("N개")`.
- [x] `UploadFileDetailView`: `InfoRow`(이름, 경로, 크기, 수정 시각, 종류). 버튼은 [Quick Look], [다운로드 폴더에 저장](캐시를 `~/Downloads`로 복사, 번호 규칙 적용), [Finder에서 보기].
- [x] `DetailViewForMac`의 `.uploadBrowser` case를 연결한다.

---

## Phase 4 — 마무리 (M4)

### T4.1 오류 상세에서 실시간 로그로 진입 · S · P2 · F1-13 · → T2.4, T2.5
- [x] `ErrorCloudItemView.UserRow`에 "실시간 로그" 액션을 추가한다.
  - iOS: `UserLogViewForIOS(initialNumber:)`로 push한다.
  - macOS: `nav.selectedSidebarItem = .userLogTail`과 `nav.userLogTarget`을 설정한다.

### T4.2 P2 편의 기능 · M · P2
- [ ] 최근 사용자 번호 10개를 `@AppStorage`에 JSON으로 저장한다(F1-14).
- [ ] Quick Look에서 같은 디렉터리의 이미지를 좌우로 넘긴다(F3-10). `.quickLookPreview(_:in:)`을 쓰고, 이미 받은 파일만 대상으로 한다.
- [ ] 업로드 경로를 직접 입력해 이동한다(F3-11).
- [ ] macOS `UploadFileDetailView`에 이미지 인라인 미리보기를 넣는다.

### T4.3 문서 갱신 · S
- [x] `CLAUDE.md`에서 오래된 내용을 고친다.
  - 실제 구조: `model/services/*Service.swift` 계층, `ViewModel`은 facade(226줄).
  - swift-log SPM 의존성이 있다.
  - 테스트 타깃 상태.
  - InfoRow2/3는 없다.
- [x] `CLAUDE.md` Repository Structure에 `model/Ops/`, `views/common/Ops/`, `views/ios/ops/`를 추가한다.
- [ ] 이 문서들의 상태를 Draft에서 Done으로 바꾸고, 바뀐 결정 사항을 반영한다. — 결정 사항은 반영(spec §14), Done 전환은 QA 이후

### T4.4 수동 QA · M

**F1 사용자 로그**
- [ ] 정상 번호 시작: 3초 안에 초기 200줄이 표시된다.
- [ ] `UT00000109114`, ` ut109114 `처럼 다양하게 입력해도 정규화된다. `0`, `abc`는 비활성화된다.
- [ ] 없는 번호: "찾을 수 없음"과 base 확인 안내가 표시된다.
- [ ] base 4종(자동 포함)을 전환하면 각각 다른 파일을 조회한다.
- [ ] 서버에서 `echo "test" >> UT….log`를 하면 1초 안에 앱에 표시된다.
- [ ] 5,000줄을 넘으면 오래된 줄이 버려지고 배지 숫자가 늘어난다.
- [ ] 위로 스크롤하면 따라가기가 해제되고, 토글을 다시 켜면 맨 아래로 이동한다.
- [ ] iOS: 백그라운드로 갔다가 돌아오면 자동으로 재연결된다(버퍼 초기화).
- [ ] 비행기 모드로 오류가 난 뒤 [재연결]하면 회복된다.
- [ ] 화면을 벗어나면 서버 쪽 연결도 끊긴다(서버 로그 또는 `lsof`로 확인).
- [ ] 한글 로그가 깨지지 않는다.
- [ ] 10분 동안 아무것도 기록되지 않아도 연결이 유지되고, 이후 새 줄을 받는다.
- [ ] 전체 다운로드: iOS는 공유와 미리보기, macOS는 `~/Downloads` 저장과 Finder 표시. 실패하면 오류가 표시된다.

**F2 서버 로그**
- [ ] 4종 모두 폴더, 파일, 내용 순서로 조회된다.
- [ ] Backend base 3종을 전환하면 다른 목록이 표시된다.
- [ ] 루트에 있는 파일과 폴더 안에 있는 파일 모두 조회된다.
- [ ] `.gz` 파일 내용이 압축 해제되어 표시되고, iOS 다운로드는 공유만 노출된다.
- [ ] tail 10000으로 스크롤해도 끊김이 없다. 검색 이동이 동작한다.
- [ ] truncated 배지가 표시되고, 표식 줄은 본문에 없다.
- [ ] macOS에서 같은 파일을 두 번 다운로드하면 `name (1).log`로 저장된다.
- [ ] NAS 미마운트 환경(로컬 서버)에서 경고 배너가 표시된다.

**F3 업로드**
- [ ] 루트부터 3단계 이상 깊이 탐색하고 다시 돌아온다(iOS 뒤로가기, macOS 브레드크럼과 상위 버튼).
- [ ] 한글, 공백, `+`, `#`이 들어간 파일 이름도 열린다.
- [ ] 이미지, PDF, 텍스트, 동영상, 알 수 없는 형식을 Quick Look으로 확인한다(알 수 없는 형식은 공유로 처리된다).
- [ ] 50MB를 넘는 파일은 확인 대화상자가 뜨고, 받는 도중 취소할 수 있다.
- [ ] 같은 파일을 다시 열면 즉시 열린다(캐시 적중).
- [ ] 필터와 정렬 조합에서도 디렉터리가 항상 위에 있다.

**공통**
- [ ] 미지원 서버(해당 API가 없는 서버)를 가리키는 환경에서 세 기능 모두 "지원하지 않는 서버" 안내를 표시한다.
- [ ] 토큰이 무효해진 상황(서버 `JWT_SECRET_KEY` 변경 후 재기동)에서 자동으로 재발급받고 성공한다.
- [ ] 24시간이 지난 캐시 파일이 앱을 다시 시작할 때 삭제된다(파일 날짜를 조작해서 확인).
- [ ] 다크 모드, Dynamic Type(큰 글꼴), iPad와 macOS 창 크기를 바꿔도 레이아웃이 깨지지 않는다.
