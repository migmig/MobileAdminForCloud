# Tasks — 사용자 로그 인터페이스 흐름 (타임라인)

| 항목 | 내용 |
|---|---|
| 문서 상태 | 구현 완료 — 수동 QA(T5.4) 남음 |
| 작성일 | 2026-11-03 |
| 관련 문서 | [spec.md](./spec.md) |

**크기:**
- **S**: 반나절 이하
- **M**: 1일 안팎
- **L**: 2일 이상

**표기:** `→`는 선행 작업, `§`는 spec 절 번호를 뜻한다. `[x]`는 완료.

---

## 진행 현황

| 구분 | 상태 |
|---|---|
| Phase 1 모델·분석 | 완료 — 테스트 22개 통과 |
| Phase 2 네트워킹·상태 모델 | 완료 — 서비스 테스트 2개, 상태 모델 테스트 8개 통과 |
| Phase 3 공통 화면 | 완료 — macOS·iOS 빌드 통과 |
| Phase 4 플랫폼 연결 | 완료 — macOS·iOS 빌드 통과 |
| Phase 5 P2·마무리 | T5.1 ~ T5.3 완료, **T5.4 수동 QA 남음** |

**검증 (2026-11-03)**
- `make build-macos`, `make build-ios` 통과, 새 파일에서 경고 없음
- 단위 테스트 296개 중 295개 통과. 새로 추가한 33개(디코딩 7, 분석 16, 서비스 2, 상태 모델 8)는 모두 통과
  - 실패 1건 `UtilTests.combineTodayWithTime_emptyString_returnsNil`은 이전부터 있던 실패로 이번 변경과 무관
- 실서버 연동과 화면 동작은 아직 확인하지 않음 (T5.4)

---

## 공통 완료 기준 (모든 태스크)

- `make build` (macOS + iOS) 경고 추가 없이 통과
- 새 로직에는 단위 테스트, 기존 테스트 깨지지 않음
- 주석은 한국어, 파일 머리 주석과 `// MARK: -`는 주변 코드와 같은 형식

## 테스트 실행 방법

`MobileAdminTests` 타깃이 pbxproj에 없어(기존 tasks T0.1) `make test`를 쓸 수 없다.
대신 SwiftPM 하네스로 실행한다. 임시 디렉터리에 아래 `Package.swift`를 두고, `Sources/MobileAdmin` → `MobileAdmin/`, `Tests/MobileAdminTests` → `MobileAdminTests/`로 심볼릭 링크를 건 뒤 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`.

```swift
// swift-tools-version:5.10
import PackageDescription
let package = Package(
    name: "MobileAdminHarness",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "<repo>/build/DerivedData/SourcePackages/checkouts/swift-log")],  // make build 후 생김
    targets: [
        .target(name: "MobileAdmin", dependencies: [.product(name: "Logging", package: "swift-log")],
                path: "Sources/MobileAdmin",
                exclude: ["MobileAdminApp.swift", "Assets.xcassets", "Preview Content", "config", "MobileAdmin.entitlements"]),
        .testTarget(name: "MobileAdminTests", dependencies: ["MobileAdmin"],
                    path: "Tests/MobileAdminTests", exclude: ["MobileAdminTests.swift"]),  // 라이브 서버 테스트 제외
    ]
)
```

---

## Phase 1 — 모델과 분석 함수

- [x] **T1.1 응답 모델** · S · §5.1
  - `model/Ops/UserLogTimeline.swift`: `TimelineKind`, `TimelineStatus`(모르는 값은 `.unknown`), `TimelineEvent`, `TimelineDate`, `UserLogTimeline`
  - `dates`/`events`가 null이거나 없으면 빈 배열, `TimelineEvent`는 `seq`로만 비교
  - 테스트용 기본값 init
- [x] **T1.2 분석 함수** · M · §5.2, §5.3 · → T1.1
  - `model/Ops/UserLogTimelineAnalysis.swift`: 세션(5분), 요청 묶음(1.5초 / 두 번째 API), 필터, 통계, 화면용 섹션 구성
  - `TimelineFormat`: `duration`, `timeOfDay`, `shortThread`, `prettyBody`(키 순서 유지), `clock`(UTC)
- [x] **T1.3 단위 테스트** · S · §7 · → T1.2
  - `UserLogTimelineDecodingTests.swift`, `UserLogTimelineAnalysisTests.swift` — 웹 `userLogTimeline.test.ts` 케이스 전부 + 경계값

## Phase 2 — 네트워킹과 상태 모델

- [x] **T2.1 `fetchJSON` timeout, `UserLogService.fetchTimeline`** · S · §4 · → T1.1
- [x] **T2.2 `UserLogTimelineModel`** · M · §6.1 · → T1.2, T2.1
  - 로드/날짜 변경/다시 불러오기/취소, 늦은 응답 버리기, 이전 결과 유지
  - 필터 변경 시 섹션 재계산(검색어 300ms 디바운스, 백그라운드 계산), `focus`
  - 서비스 주입(클로저) — `UserLogTailModel`과 같은 방식
- [x] **T2.3 상태 모델 테스트** · S · §7 · → T2.2

## Phase 3 — 공통 화면

- [x] **T3.1 이벤트 행, 묶음 헤더, 배지** · M · §6.5 · → T1.2
  - `views/common/Ops/UserLog/TimelineEventRow.swift`
- [x] **T3.2 이벤트 상세** · M · §6.6 · → T1.2
  - `views/common/Ops/UserLog/TimelineEventDetailView.swift` — 메타, 헤더, 메시지, 요청/응답 + 복사
- [x] **T3.3 흐름 화면** · L · §6.4 · → T2.2, T3.1, T3.2
  - `views/common/Ops/UserLog/UserLogTimelineView.swift` — 날짜 바, 잘림 안내, 요약, 필터, 세션 목록, 상태별 화면

## Phase 4 — 플랫폼 연결

- [x] **T4.1 `UserLogForm` "흐름 분석" 버튼** · S · §6.2
- [x] **T4.2 iOS `UserLogViewForIOS` 보기 전환** · M · §6.3 · → T3.3, T4.1
  - 세그먼트 전환, 두 모델 유지, 이벤트 상세 push, `initialMode`, 홈 메뉴 설명 문구
- [x] **T4.3 macOS 사이드바·상세 컬럼** · M · §6.3 · → T3.3, T4.1
  - `NavigationState`에 요청·모드, 상세 컬럼 툴바 전환, `.inspector` 상세
- [x] **T4.4 마지막 보기 모드 기억** · S · Q3 · → T4.2, T4.3

## Phase 5 — P2와 마무리

- [x] **T5.1 오류 조회에서 흐름 분석 진입** · S · §6.2, Q5 · → T4.2, T4.3
- [x] **T5.2 세션 시간 막대(macOS), 소요시간 막대** · M · §6.4, §6.5 · → T3.3
- [x] **T5.3 문서 갱신** · S — CLAUDE.md 구조, spec 변경 사항
- [ ] **T5.4 수동 QA** · M · §7 — 실서버(V1/V2 로그), 대량 이벤트, 미지원 서버, 보기 전환 중 스트림 유지
