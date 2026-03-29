# Kubernetes Rollout Status and Events Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add deployment rollout status and resource-related events to the existing macOS Kubernetes detail pane without adding new routes or screens.

**Architecture:** Extend `KubernetesService` with bounded rollout status retrieval and namespace event decoding/filtering, then expose the new read-only state through `ViewModel` into `KubernetesDetailViewForMac`. Keep the existing single Kubernetes route and centralize selection/reset behavior enough to prevent stale rollout/event content from surviving namespace, context, or resource changes.

**Tech Stack:** Swift, SwiftUI, Foundation, Apple's Testing framework, xcodebuild, kubectl

---

## File Structure

- Create: `MobileAdmin/model/DevTools/KubernetesEventInfo.swift` — display-oriented event model plus minimal decode helpers.
- Modify: `MobileAdmin/model/services/KubernetesService.swift` — rollout status + events APIs and decoding/filtering.
- Modify: `MobileAdmin/model/ViewModel.swift` — rollout/event published state, reset helpers, and selection-driven loading.
- Modify: `MobileAdmin/model/NavigationState.swift` — small helper to clear Kubernetes selections together.
- Modify: `MobileAdmin/views/macos/KubernetesListViewForMac.swift` — selection clearing plus operational-detail triggers.
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift` — rollout status and events sections.
- Modify: `MobileAdminTests/KubernetesServiceTests.swift` — rollout status and event parsing/filtering tests.
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift` — rollout/events state and stale-reset tests.

### Task 1: Service and model support

**Files:**
- Create: `MobileAdmin/model/DevTools/KubernetesEventInfo.swift`
- Modify: `MobileAdmin/model/services/KubernetesService.swift`
- Modify: `MobileAdminTests/KubernetesServiceTests.swift`

- [ ] **Step 1: Write the failing rollout status and events tests**

Add tests to `MobileAdminTests/KubernetesServiceTests.swift` for:

```swift
@Test func fetchRolloutStatus_passesDeploymentNamespaceAndTimeout() async throws
@Test func fetchEvents_decodesAndFiltersMatchingResourceEvents() async throws
@Test func fetchEvents_invalidJSON_wrapsDecodeFailure() async throws
```

Key expectations:

```swift
#expect(runner.recordedArguments == [["rollout", "status", "deployment/api", "-n", "prod", "--timeout=10s"]])
#expect(events.map(\.reason) == ["ScalingReplicaSet", "Started"])
```

- [ ] **Step 2: Run the targeted service test suite and verify it fails for the expected missing APIs/models**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesServiceTests'
```

Expected: FAIL because `fetchRolloutStatus`, `fetchEvents`, and `KubernetesEventInfo` do not exist yet.

- [ ] **Step 3: Implement the minimal event model and service APIs**

Create `MobileAdmin/model/DevTools/KubernetesEventInfo.swift` with:

```swift
import Foundation

struct KubernetesEventInfo: Equatable, Hashable, Identifiable {
    let type: String
    let reason: String
    let message: String
    let involvedKind: String
    let involvedName: String
    let timestampText: String

    var id: String { [involvedKind, involvedName, reason, timestampText].joined(separator: ":") }
}

struct KubernetesEventListResponse: Codable {
    let items: [KubernetesEventItem]
}

struct KubernetesEventItem: Codable {
    let type: String?
    let reason: String?
    let message: String?
    let eventTime: String?
    let lastTimestamp: String?
    let firstTimestamp: String?
    let involvedObject: KubernetesEventInvolvedObject
}

struct KubernetesEventInvolvedObject: Codable {
    let kind: String?
    let name: String?
}
```

Extend `KubernetesService` with:

```swift
func fetchRolloutStatus(deployment: String, namespace: String) async throws -> String {
    let result = try await runner.run(arguments: ["rollout", "status", "deployment/\(deployment)", "-n", namespace, "--timeout=10s"])
    return result.stdout
}

func fetchEvents(namespace: String, resourceKind: String, resourceName: String) async throws -> [KubernetesEventInfo] {
    let command = ["get", "events", "-n", namespace, "-o", "json"]
    let result = try await runner.run(arguments: command)
    let decoded = try decode(KubernetesEventListResponse.self, from: result.stdout, command: command)
    return decoded.items
        .filter { ($0.involvedObject.kind ?? "") == resourceKind && ($0.involvedObject.name ?? "") == resourceName }
        .map {
            KubernetesEventInfo(
                type: $0.type ?? "",
                reason: $0.reason ?? "",
                message: $0.message ?? "",
                involvedKind: $0.involvedObject.kind ?? "",
                involvedName: $0.involvedObject.name ?? "",
                timestampText: $0.eventTime ?? $0.lastTimestamp ?? $0.firstTimestamp ?? ""
            )
        }
}
```

- [ ] **Step 4: Run the targeted service test suite and verify it passes**

Run the same command from Step 2.

Expected: targeted service tests pass.

- [ ] **Step 5: Commit the service/model slice**

```bash
git add MobileAdmin/model/DevTools/KubernetesEventInfo.swift MobileAdmin/model/services/KubernetesService.swift MobileAdminTests/KubernetesServiceTests.swift
git commit -m "Add Kubernetes rollout and events service"
```

### Task 2: ViewModel state and selection reset

**Files:**
- Modify: `MobileAdmin/model/ViewModel.swift`
- Modify: `MobileAdmin/model/NavigationState.swift`
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Write the failing ViewModel tests for rollout/event loading and stale reset**

Add tests to `MobileAdminTests/ViewModelKubernetesTests.swift`:

```swift
@Test func loadSelectedDeploymentOperationalDetails_setsRolloutStatusAndEvents() async
@Test func loadSelectedPodOperationalDetails_setsEventsAndClearsRolloutStatus() async
@Test func refreshKubernetesOverview_clearsStaleRolloutAndEventsOnNamespaceChange() async
```

- [ ] **Step 2: Run the targeted ViewModel suite and verify it fails for missing state/methods**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
```

Expected: FAIL because rollout/event state and loaders do not exist yet.

- [ ] **Step 3: Implement the minimal ViewModel and NavigationState changes**

Add to `ViewModel`:

```swift
@Published var kubeEvents: [KubernetesEventInfo] = []
@Published var selectedRolloutStatus: String = ""
@Published var isKubernetesActionLoading = false
```

Add helpers:

```swift
@MainActor func resetKubernetesOperationalState()
@MainActor func loadSelectedDeploymentOperationalDetails() async
@MainActor func loadSelectedPodOperationalDetails() async
```

Behavior:
- deployment loader fetches rollout status + events
- pod loader clears rollout status and fetches events
- `refreshKubernetesOverview()` and `switchKubernetesContext(to:)` call `resetKubernetesOperationalState()` before/while reloading

Add to `NavigationState`:

```swift
func clearKubernetesSelections() {
    selectedKubePod = nil
    selectedKubeDeployment = nil
    selectedKubeService = nil
    selectedKubeConfigMap = nil
    selectedKubeSecret = nil
}
```

- [ ] **Step 4: Run the targeted ViewModel suite and verify it passes**

Run the same command from Step 2.

Expected: targeted ViewModel tests pass.

- [ ] **Step 5: Commit the state/reset slice**

```bash
git add MobileAdmin/model/ViewModel.swift MobileAdmin/model/NavigationState.swift MobileAdminTests/ViewModelKubernetesTests.swift
git commit -m "Add Kubernetes rollout and events state"
```

### Task 3: macOS list/detail wiring

**Files:**
- Modify: `MobileAdmin/views/macos/KubernetesListViewForMac.swift`
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift`

- [ ] **Step 1: Add the smallest integration test expectations in ViewModel tests if needed**

If the list/detail trigger logic needs one more failing test, add it before UI code rather than after.

- [ ] **Step 2: Implement list selection clearing and operational-detail loading**

In `KubernetesListViewForMac.swift`:

- when selecting a deployment/service/configMap/secret via button, call `nav.clearKubernetesSelections()` first, then set the one selection you want
- when pod selection changes, clear the non-pod Kubernetes selections
- trigger the appropriate ViewModel loader for deployment or pod
- clear rollout/events for unsupported resource kinds in this slice

- [ ] **Step 3: Implement rollout and events sections in the detail pane**

In `KubernetesDetailViewForMac.swift`, add:

```swift
Section("Rollout Status") { ... }
Section("Events") { ... }
```

Rules:
- rollout section only when a deployment is selected
- events section for deployment or pod selections in this slice
- use explicit empty text for no events / no rollout data
- keep existing `kubernetesError` display

- [ ] **Step 4: Run targeted tests and then the broadest available verification**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesServiceTests'
xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: targeted tests and build pass. If local Xcode is unavailable, record the exact blocker and still run the strongest available partial verification.

- [ ] **Step 5: Commit the UI slice**

```bash
git add MobileAdmin/views/macos/KubernetesListViewForMac.swift MobileAdmin/views/macos/KubernetesDetailViewForMac.swift
git commit -m "Show Kubernetes rollout status and events"
```
