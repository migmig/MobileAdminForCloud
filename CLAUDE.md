# CLAUDE.md - AI Assistant Guide for MobileAdminForCloud

## Project Overview

MobileAdminForCloud is a **cross-platform iOS/macOS admin dashboard application** built with SwiftUI. It provides cloud infrastructure management capabilities including error monitoring, product/goods tracking, education course management, and DevOps tooling (build, deploy, pipeline, and commit management).

- **Language:** Swift
- **UI Framework:** SwiftUI with platform-conditional compilation (`#if os(iOS)` / `#if os(macOS)`)
- **Data Persistence:** SwiftData (Apple's modern persistence framework)
- **Authentication:** JWT tokens + biometric auth (Face ID / Touch ID via LocalAuthentication)
- **No external dependencies** - uses only Apple frameworks (Foundation, SwiftUI, SwiftData, LocalAuthentication, AVKit, Combine, Logging, UIKit/AppKit)

## Repository Structure

```
MobileAdminForCloud/
├── MobileAdmin/                          # Main app source
│   ├── MobileAdminApp.swift              # @main entry point, ModelContainer setup, AppDelegate
│   ├── Scense/                           # Platform-specific root scenes
│   │   ├── MySceneForIOS.swift           # iOS root: TabView with biometric auth
│   │   └── MySceneForMacOS.swift         # macOS root: NavigationSplitView (3-column)
│   ├── views/                            # All UI views
│   │   ├── common/                       # Shared cross-platform views
│   │   │   ├── ErrorCloud/               # Error monitoring views
│   │   │   ├── Goods/                    # Product/goods views
│   │   │   ├── devTools/                 # Build, deploy, pipeline, commit detail views
│   │   │   ├── EnvSetView.swift          # Environment configuration (first-run setup)
│   │   │   ├── SettingsView.swift        # App settings
│   │   │   ├── InfoRow.swift/2/3         # Reusable key-value row components
│   │   │   └── ToastView.swift           # Toast CRUD management
│   │   ├── ios/                          # iOS-specific views (suffix: *IOS or *ForIOS)
│   │   │   ├── HomeViewForIOS.swift      # iOS home tab with navigation links
│   │   │   ├── devTools/                 # iOS DevTools tab views
│   │   │   └── *ListViewIOS.swift        # iOS list screens
│   │   └── macos/                        # macOS-specific views (suffix: *ForMac)
│   │       ├── ContentViewForMac.swift   # 3-column NavigationSplitView layout
│   │       ├── SlidebarViewForMac.swift  # Sidebar navigation categories
│   │       ├── *Sidebar.swift            # Category-specific sidebar filters
│   │       └── DetailViewForMac.swift    # Right detail pane
│   ├── model/                            # Data models and API layer
│   │   ├── ViewModel.swift               # Central API client (~612 lines), ObservableObject
│   │   ├── TokenRequest.swift            # Auth token request model
│   │   ├── Cloud/                        # Cloud service models (Codable structs)
│   │   │   ├── EnvironmentModel.swift    # SwiftData @Model for server URLs
│   │   │   ├── ErrorCloudItem.swift      # Error log entries
│   │   │   ├── Goodsinfo.swift           # Product info with nested structures
│   │   │   ├── Toast.swift               # Notification messages
│   │   │   ├── EdcCrse*.swift            # Education course models
│   │   │   └── CmmnCode*.swift           # Common code/group code models
│   │   ├── DevTools/                     # DevOps pipeline models
│   │   │   ├── SourceBuildInfo.swift      # Build projects and status
│   │   │   ├── SourceCommitInfo.swift     # Git commit/repository data
│   │   │   ├── SourceDeployStageInfo.swift # Deployment stages/scenarios
│   │   │   ├── SourcePipelineHistoryInfo.swift # Pipeline execution history
│   │   │   └── ...                        # Other build/deploy/pipeline models
│   │   └── Legacy/                        # Deprecated models (unused)
│   ├── components/                        # Reusable UI components
│   │   ├── CrossPlatformVideoPlayer.swift # AVKit wrapper (iOS/macOS)
│   │   ├── FilteredGoodsItem.swift        # Filtered product list item
│   │   ├── KorDatePicker.swift            # Korean locale date picker
│   │   └── SearchArea.swift               # Search input component
│   ├── Util/                              # Utilities
│   │   ├── Util.swift                     # Date formatting, clipboard, JSON formatting
│   │   ├── EnvironmentType.swift          # Environment enum (development/production/local)
│   │   ├── Effect.swift                   # SwiftUI transition animations
│   │   ├── ToastManager.swift             # Toast notification state (ObservableObject)
│   │   └── ToastModifier.swift            # Toast ViewModifier
│   ├── commands/                          # macOS menu commands
│   │   └── MyCommands.swift
│   ├── config/
│   │   └── Info.plist                     # App config (NSAppTransportSecurity, adminCI token)
│   ├── Assets.xcassets/                   # Image and color assets
│   └── Preview Content/                   # SwiftUI preview assets
├── MobileAdminTests/                      # Unit tests (Apple Testing framework)
│   └── MobileAdminTests.swift             # Token validation, API fetch tests
├── MobileAdminUITests/                    # UI tests
│   ├── MobileAdminUITests.swift
│   └── MobileAdminUITestsLaunchTests.swift
├── MobileAdmin.xcodeproj/                 # Xcode project configuration
├── MobileAdmin.xctestplan                 # Test plan configuration
└── README.md
```

## Architecture

### Pattern: MVVM (Model-View-ViewModel)

- **Model:** Codable structs in `model/Cloud/` and `model/DevTools/`
- **ViewModel:** Single `ViewModel.swift` (ObservableObject) serves as the API client and state holder
- **View:** SwiftUI views in `views/` consume ViewModel via `@EnvironmentObject`

### Navigation Architecture

**iOS:**
```
MobileAdminApp -> MySceneForIOS -> TabView
  ├── HomeViewForIOS (NavigationStack -> detail views)
  ├── CloseDeptListViewIOS
  ├── SourceControlViewForIOS (DevTools)
  └── SettingsView
```

**macOS:**
```
MobileAdminApp -> MySceneForMacOS -> NavigationSplitView (3-column)
  ├── SlidebarViewForMac (sidebar: category selection)
  ├── ContentListViewForMac (list column)
  └── DetailViewForMac (detail column)
```

Both platforms show `EnvSetView` on first launch if no environment is configured.

### API Communication

All network calls go through `ViewModel.swift` using three generic methods:

| Method | Description |
|---|---|
| `makeRequest<R, T>(url:requestData:)` | POST with request body, returns decoded response |
| `makeRequestNoRequestData<T>(url:)` | POST without body, returns decoded response |
| `makeRequestNoReturn<T>(url:requestData:)` | POST with body, no response parsing |

- **Auth:** JWT Bearer token obtained via `/simpleLoginForAdmin`
- **Token refresh:** Automatic check before each request; refreshes if expired
- **Base URL:** Configured via `EnvironmentConfig` (stored in SwiftData)
- **Headers:** `Content-Type: application/json`, `Accept: */*`, `Authorization: Bearer {token}`

## Build & Development

### Build System

This is a native Xcode project (no SPM, CocoaPods, or Carthage). Build using:

```bash
# Build (requires Xcode and macOS)
xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Framework

- Uses Apple's modern **Testing** framework (`@Test` macro, not XCTest)
- Test plan: `MobileAdmin.xctestplan` targeting `MobileAdminTests`
- Tests cover token validation and API fetch operations

## Coding Conventions

### File Naming

| Pattern | Example | Usage |
|---|---|---|
| `*ViewForIOS.swift` | `ErrorListViewForIOS.swift` | iOS-specific views |
| `*ViewIOS.swift` | `CloseDeptListViewIOS.swift` | iOS-specific views (alternate) |
| `*ForMac.swift` | `ContentViewForMac.swift` | macOS-specific views |
| `*Sidebar.swift` | `ErrorSidebar.swift` | macOS sidebar filter views |
| `*Detail*.swift` | `EdcCrseDetailView.swift` | Detail/drill-down views |
| `Source*.swift` | `SourceBuildInfo.swift` | DevTools models |

### SwiftUI Patterns

- **State management:** `@StateObject` for ViewModel/ToastManager creation, `@EnvironmentObject` for injection
- **Platform branching:** `#if os(iOS)` / `#elseif os(macOS)` at the top level
- **Async data loading:** `.task { }` modifier with `async/await`
- **View modifiers:** Custom modifiers for toast notifications (`.toastManager(toastManager:)`)
- **Section organization:** `// MARK: -` comments in model files

### Data Model Conventions

- All API models conform to `Codable` (JSON serialization)
- Models used in SwiftUI Lists conform to `Identifiable`
- Models used in Sets/comparisons conform to `Hashable`
- Multiple initializers: empty `init()`, convenience, and full-parameter versions
- `EnvironmentModel` is the only SwiftData `@Model` (persistent storage for server URLs)

### Code Comments

- Comments are primarily in **Korean** (the development team's language)
- Use `// MARK: -` for section headers in longer files

### Environment Configuration

Three environments defined in `EnvironmentType.swift`:

| Environment | Usage |
|---|---|
| `development` | Dev/staging server |
| `production` | Production server (default) |
| `local` | Local development server |

Color coding: each environment has distinct icon colors in the UI for visual differentiation.

## Key Files to Know

| File | Purpose |
|---|---|
| `MobileAdminApp.swift` | App entry, ModelContainer, AppDelegate (push notifications, screen sleep prevention) |
| `ViewModel.swift` | All API calls, token management, central state (~612 lines) |
| `EnvironmentType.swift` | Server URL configuration, environment switching |
| `MySceneForIOS.swift` | iOS root scene with biometric auth and TabView |
| `MySceneForMacOS.swift` | macOS root scene with 3-column NavigationSplitView |
| `Util.swift` | Date formatting, clipboard, JSON formatting utilities |
| `ToastManager.swift` + `ToastModifier.swift` | Toast notification system |
| `EnvSetView.swift` | First-run environment setup screen |

## Security Considerations

- **adminCI** credential is embedded in `Info.plist` (Base64 encoded) - do not expose
- JWT tokens are held in static memory (not persisted to disk)
- `NSAllowsArbitraryLoads = true` in ATS config (allows plain HTTP - needed for local/dev environments)
- Biometric authentication gates app access on iOS

## Common Tasks for AI Assistants

### Adding a new API endpoint
1. Add the API call method in `ViewModel.swift` following the existing `async throws` pattern
2. Create request/response model structs in `model/Cloud/` or `model/DevTools/` conforming to `Codable`
3. Add `@Published` property to ViewModel if the data needs to be observed by views

### Adding a new view
1. Create shared views in `views/common/`
2. Create platform-specific views in `views/ios/` or `views/macos/` with appropriate naming suffixes
3. Wire navigation in `HomeViewForIOS.swift` (iOS) or `SlidebarViewForMac.swift` + `ContentListViewForMac.swift` + `DetailViewForMac.swift` (macOS)
4. Use `@EnvironmentObject var viewModel: ViewModel` for data access

### Adding a new data model
1. Create a new Swift file in `model/Cloud/` or `model/DevTools/`
2. Conform to `Codable`, `Identifiable`, and `Hashable` as needed
3. Provide an empty `init()` and a full-parameter initializer
