# MobileAdminForCloud (모바일 클라우드 관리자)

## 프로젝트 개요

MobileAdminForCloud는 SwiftUI로 빌드된 **크로스 플랫폼 iOS/macOS 관리자 대시보드 애플리케이션**입니다. 오류 모니터링, 제품/상품 추적, 교육 과정 관리 및 DevOps 도구(빌드, 배포, 파이프라인 및 커밋 관리)를 포함한 클라우드 인프라 관리 기능을 제공합니다.

- **언어:** Swift
- **UI 프레임워크:** 플랫폼 조건부 컴파일을 사용한 SwiftUI (`#if os(iOS)` / `#if os(macOS)`)
- **데이터 영속성:** SwiftData (Apple의 최신 영속성 프레임워크)
- **인증:** JWT 토큰 + 생체 인증 (LocalAuthentication을 통한 Face ID / Touch ID)
- **외부 종속성 없음** - Apple 프레임워크만 사용합니다 (Foundation, SwiftUI, SwiftData, LocalAuthentication, AVKit, Combine, Logging, UIKit/AppKit)

## 저장소 구조

```text
MobileAdminForCloud/
├── MobileAdmin/                          # 메인 앱 소스
│   ├── MobileAdminApp.swift              # @main 진입점, ModelContainer 설정, AppDelegate
│   ├── Scense/                           # 플랫폼별 루트 씬
│   │   ├── MySceneForIOS.swift           # iOS 루트: 생체 인증이 포함된 TabView
│   │   └── MySceneForMacOS.swift         # macOS 루트: NavigationSplitView (3-단)
│   ├── views/                            # 모든 UI 뷰
│   │   ├── common/                       # 공유 크로스 플랫폼 뷰
│   │   │   ├── ErrorCloud/               # 오류 모니터링 뷰
│   │   │   ├── Goods/                    # 제품/상품 뷰
│   │   │   ├── devTools/                 # 빌드, 배포, 파이프라인, 커밋 상세 뷰
│   │   │   ├── EnvSetView.swift          # 환경 설정 (첫 실행 설정)
│   │   │   ├── SettingsView.swift        # 앱 설정
│   │   │   ├── InfoRow.swift/2/3         # 재사용 가능한 키-값 행 컴포넌트
│   │   │   └── ToastView.swift           # 토스트 CRUD 관리
│   │   ├── ios/                          # iOS 전용 뷰 (접미사: *IOS 또는 *ForIOS)
│   │   │   ├── HomeViewForIOS.swift      # 네비게이션 링크가 있는 iOS 홈 탭
│   │   │   ├── devTools/                 # iOS DevTools 탭 뷰
│   │   │   └── *ListViewIOS.swift        # iOS 목록 화면
│   │   └── macos/                        # macOS 전용 뷰 (접미사: *ForMac)
│   │       ├── ContentViewForMac.swift   # 3-단 NavigationSplitView 레이아웃
│   │       ├── SlidebarViewForMac.swift  # 사이드바 네비게이션 카테고리
│   │       ├── *Sidebar.swift            # 카테고리별 사이드바 필터
│   │       └── DetailViewForMac.swift    # 우측 상세 창
│   ├── model/                            # 데이터 모델 및 API 계층
│   │   ├── ViewModel.swift               # 중앙 API 클라이언트 (~612줄), ObservableObject
│   │   ├── TokenRequest.swift            # 인증 토큰 요청 모델
│   │   ├── Cloud/                        # 클라우드 서비스 모델 (Codable 구조체)
│   │   │   ├── EnvironmentModel.swift    # 서버 URL을 위한 SwiftData @Model
│   │   │   ├── ErrorCloudItem.swift      # 오류 로그 항목
│   │   │   ├── Goodsinfo.swift           # 중첩 구조를 가진 제품 정보
│   │   │   ├── Toast.swift               # 알림 메시지
│   │   │   ├── EdcCrse*.swift            # 교육 과정 모델
│   │   │   └── CmmnCode*.swift           # 공통 코드/그룹 코드 모델
│   │   ├── DevTools/                     # DevOps 파이프라인 모델
│   │   │   ├── SourceBuildInfo.swift      # 빌드 프로젝트 및 상태
│   │   │   ├── SourceCommitInfo.swift     # Git 커밋/저장소 데이터
│   │   │   ├── SourceDeployStageInfo.swift # 배포 단계/시나리오
│   │   │   ├── SourcePipelineHistoryInfo.swift # 파이프라인 실행 역사
│   │   │   └── ...                        # 기타 빌드/배포/파이프라인 모델
│   │   └── Legacy/                        # 사용되지 않는 이전 모델
│   ├── components/                        # 재사용 가능한 UI 컴포넌트
│   │   ├── CrossPlatformVideoPlayer.swift # AVKit 래퍼 (iOS/macOS)
│   │   ├── FilteredGoodsItem.swift        # 필터링된 제품 목록 항목
│   │   ├── KorDatePicker.swift            # 한국어 로캘 날짜 선택기
│   │   └── SearchArea.swift               # 검색 입력 컴포넌트
│   ├── Util/                              # 유틸리티
│   │   ├── Util.swift                     # 날짜 포맷팅, 클립보드, JSON 포맷팅
│   │   ├── EnvironmentType.swift          # 환경 열거형 (개발/운영/로컬)
│   │   ├── Effect.swift                   # SwiftUI 전환 애니메이션
│   │   ├── ToastManager.swift             # 토스트 알림 상태 (ObservableObject)
│   │   └── ToastModifier.swift            # 토스트 ViewModifier
│   ├── commands/                          # macOS 메뉴 명령
│   │   └── MyCommands.swift
│   ├── config/
│   │   └── Info.plist                     # 앱 설정 (NSAppTransportSecurity, adminCI 토큰)
│   ├── Assets.xcassets/                   # 이미지 및 색상 에셋
│   └── Preview Content/                   # SwiftUI 미리보기 에셋
├── MobileAdminTests/                      # 단위 테스트 (Apple Testing 프레임워크)
│   └── MobileAdminTests.swift             # 토큰 검증, API 페치 테스트
├── MobileAdminUITests/                    # UI 테스트
│   ├── MobileAdminUITests.swift
│   └── MobileAdminUITestsLaunchTests.swift
├── MobileAdmin.xcodeproj/                 # Xcode 프로젝트 구성
├── MobileAdmin.xctestplan                 # 테스트 플랜 구성
└── README.md
```

## 아키텍처

### 패턴: MVVM (Model-View-ViewModel)

- **Model:** `model/Cloud/` 및 `model/DevTools/`의 Codable 구조체
- **ViewModel:** 단일 `ViewModel.swift` (ObservableObject)가 API 클라이언트 및 상태 홀더 역할 수행
- **View:** `views/`의 SwiftUI 뷰는 `@EnvironmentObject`를 통해 ViewModel을 소비함

### 네비게이션 아키텍처

**iOS:**
```text
MobileAdminApp -> MySceneForIOS -> TabView
  ├── HomeViewForIOS (NavigationStack -> 상세 뷰)
  ├── CloseDeptListViewIOS
  ├── SourceControlViewForIOS (DevTools)
  └── SettingsView
```

**macOS:**
```text
MobileAdminApp -> MySceneForMacOS -> NavigationSplitView (3-단)
  ├── SlidebarViewForMac (사이드바: 카테고리 선택)
  ├── ContentListViewForMac (목록 열)
  └── DetailViewForMac (상세 열)
```

두 플랫폼 모두 환경이 구성되지 않은 경우 첫 실행 시 `EnvSetView`를 표시합니다.

### API 통신

모든 네트워크 호출은 `ViewModel.swift`를 통해 세 가지 제네릭 메서드를 사용하여 이루어집니다:

| 메서드 | 설명 |
|---|---|
| `makeRequest<R, T>(url:requestData:)` | 요청 본문과 함께 POST, 디코딩된 응답 반환 |
| `makeRequestNoRequestData<T>(url:)` | 본문 없이 POST, 디코딩된 응답 반환 |
| `makeRequestNoReturn<T>(url:requestData:)` | 요청 본문과 함께 POST, 응답 파싱 없음 |

- **인증:** `/simpleLoginForAdmin`을 통해 획득한 JWT Bearer 토큰
- **토큰 갱신:** 각 요청 전에 자동으로 확인하고 만료 시 갱신
- **기본 URL:** `EnvironmentConfig`를 통해 구성 (SwiftData에 저장)
- **헤더:** `Content-Type: application/json`, `Accept: */*`, `Authorization: Bearer {token}`

## 빌드 및 개발

### 빌드 시스템

이는 네이티브 Xcode 프로젝트입니다 (SPM, CocoaPods, Carthage 사용 안함). 다음 명령어로 빌드합니다:

```bash
# 빌드 (Xcode 및 macOS 필요)
xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'

# 테스트 실행
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 테스트 프레임워크

- Apple의 최신 **Testing** 프레임워크 사용 (`@Test` 매크로, XCTest 아님)
- 테스트 플랜: `MobileAdminTests`를 대상으로 하는 `MobileAdmin.xctestplan`
- 테스트는 토큰 검증 및 API 페치 작업을 다룸

## 코딩 규칙

### 파일 명명

| 패턴 | 예시 | 사용처 |
|---|---|---|
| `*ViewForIOS.swift` | `ErrorListViewForIOS.swift` | iOS 전용 뷰 |
| `*ViewIOS.swift` | `CloseDeptListViewIOS.swift` | iOS 전용 뷰 (대체) |
| `*ForMac.swift` | `ContentViewForMac.swift` | macOS 전용 뷰 |
| `*Sidebar.swift` | `ErrorSidebar.swift` | macOS 사이드바 필터 뷰 |
| `*Detail*.swift` | `EdcCrseDetailView.swift` | 상세/드릴다운 뷰 |
| `Source*.swift` | `SourceBuildInfo.swift` | DevTools 모델 |

### SwiftUI 패턴

- **상태 관리:** ViewModel/ToastManager 생성에는 `@StateObject`, 주입에는 `@EnvironmentObject` 사용
- **플랫폼 분기:** 최상위 레벨에서 `#if os(iOS)` / `#elseif os(macOS)` 사용
- **비동기 데이터 로딩:** `async/await`와 함께 `.task { }` 수정자 사용
- **뷰 수정자:** 토스트 알림을 위한 커스텀 수정자 (`.toastManager(toastManager:)`)
- **섹션 구성:** 모델 파일 내에 `// MARK: -` 주석 사용

### 데이터 모델 규칙

- 모든 API 모델은 `Codable` (JSON 직렬화) 준수
- SwiftUI List에서 사용되는 모델은 `Identifiable` 준수
- Set/비교에 사용되는 모델은 `Hashable` 준수
- 여러 이니셜라이저 제공: 빈 `init()`, 편의(convenience), 전체 매개변수 버전
- `EnvironmentModel`은 유일한 SwiftData `@Model` (서버 URL을 위한 영구 저장소)

### 코드 주석

- 주석은 주로 **한국어**로 작성됨
- 긴 파일에서 섹션 헤더로 `// MARK: -` 사용

### 환경 구성

`EnvironmentType.swift`에 세 가지 환경이 정의되어 있습니다:

| 환경 | 용도 |
|---|---|
| `development` | 개발/스테이징 서버 |
| `production` | 운영 서버 (기본값) |
| `local` | 로컬 개발 서버 |

색상 코딩: 각 환경은 UI에서 시각적 구분을 위해 고유한 아이콘 색상을 가짐.

## 주요 파일

| 파일 | 목적 |
|---|---|
| `MobileAdminApp.swift` | 앱 진입점, ModelContainer, AppDelegate (푸시 알림, 화면 꺼짐 방지) |
| `ViewModel.swift` | 모든 API 호출, 토큰 관리, 중앙 상태 (~612줄) |
| `EnvironmentType.swift` | 서버 URL 구성, 환경 전환 |
| `MySceneForIOS.swift` | 생체 인증 및 TabView가 있는 iOS 루트 씬 |
| `MySceneForMacOS.swift` | 3-단 NavigationSplitView가 있는 macOS 루트 씬 |
| `Util.swift` | 날짜 포맷팅, 클립보드, JSON 포맷팅 유틸리티 |
| `ToastManager.swift` + `ToastModifier.swift` | 토스트 알림 시스템 |
| `EnvSetView.swift` | 첫 실행 환경 설정 화면 |

## 보안 고려사항

- **adminCI** 자격 증명은 `Info.plist`에 포함되어 있음 (Base64 인코딩) - 노출하지 말 것
- JWT 토큰은 정적 메모리에 유지됨 (디스크에 영구 저장되지 않음)
- ATS 설정에 `NSAllowsArbitraryLoads = true` 포함 (일반 HTTP 허용 - 로컬/개발 환경에 필요)
- iOS에서는 생체 인증을 통해 앱 접근 제어
