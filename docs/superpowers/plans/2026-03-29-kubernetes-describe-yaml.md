# Kubernetes Describe and YAML Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add read-only `describe` and YAML inspection for pods, deployments, and services to the existing macOS Kubernetes detail pane.

**Architecture:** Keep the current single `.sourceKubernetes` route and extend `KubernetesService` with fixed-function raw text fetch APIs. Route the resulting describe/YAML text through `ViewModel`, then render it inside a mode-based inspector in `KubernetesDetailViewForMac` so the detail pane scales without becoming another oversized SwiftUI view-builder.

**Tech Stack:** Swift, SwiftUI, Foundation, Apple's Testing framework, xcodebuild, kubectl

---

## File Structure

- Modify: `MobileAdmin/model/services/KubernetesService.swift` — add describe/YAML APIs and raw text command handling.
- Modify: `MobileAdmin/model/ViewModel.swift` — add document state, reset helpers, and selection-aware loading.
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift` — add inspector mode UI and describe/YAML panels.
- Modify: `MobileAdmin/views/macos/KubernetesListViewForMac.swift` — trigger describe/YAML state resets and supported-resource loading on selection changes.
- Modify: `MobileAdminTests/KubernetesServiceTests.swift` — add describe/YAML command tests.
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift` — add document state load/reset tests.
- Optional small helper if needed: `MobileAdmin/model/DevTools/KubernetesInspectorMode.swift` or a local enum in the detail view.

### Task 1: Service-layer describe and YAML support

**Files:**
- Modify: `MobileAdmin/model/services/KubernetesService.swift`
- Modify: `MobileAdminTests/KubernetesServiceTests.swift`

- [ ] **Step 1: Write the failing service tests**

Add these tests to `MobileAdminTests/KubernetesServiceTests.swift`:

```swift
@Test func fetchPodDescribe_passesPodCommandArguments() async throws
@Test func fetchDeploymentDescribe_passesDeploymentCommandArguments() async throws
@Test func fetchResourceYAML_passesKindNameNamespaceAndYamlFlag() async throws
```

Key expectations:

```swift
#expect(runner.recordedArguments == [["describe", "pod", "api-123", "-n", "prod"]])
#expect(runner.recordedArguments == [["describe", "deployment", "api", "-n", "prod"]])
#expect(runner.recordedArguments == [["get", "service", "api", "-n", "prod", "-o", "yaml"]])
```

- [ ] **Step 2: Run the targeted service test suite and verify it fails**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesServiceTests'
```

Expected: FAIL because the new describe/YAML APIs do not exist yet.

- [ ] **Step 3: Implement the minimal service APIs**

Add to `KubernetesServicing` and `KubernetesService`:

```swift
func fetchPodDescribe(name: String, namespace: String) async throws -> String
func fetchDeploymentDescribe(name: String, namespace: String) async throws -> String
func fetchResourceYAML(kind: String, name: String, namespace: String) async throws -> String
```

Implementation shape:

```swift
func fetchPodDescribe(name: String, namespace: String) async throws -> String {
    let result = try await runner.run(arguments: ["describe", "pod", name, "-n", namespace])
    return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
}

func fetchDeploymentDescribe(name: String, namespace: String) async throws -> String {
    let result = try await runner.run(arguments: ["describe", "deployment", name, "-n", namespace])
    return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
}

func fetchResourceYAML(kind: String, name: String, namespace: String) async throws -> String {
    let result = try await runner.run(arguments: ["get", kind, name, "-n", namespace, "-o", "yaml"])
    return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
}
```

- [ ] **Step 4: Re-run the targeted service tests**

Run the same command from Step 2.

Expected: targeted describe/YAML service tests pass.

- [ ] **Step 5: Commit the service slice**

```bash
git add MobileAdmin/model/services/KubernetesService.swift MobileAdminTests/KubernetesServiceTests.swift
git commit -m "Add Kubernetes describe and YAML service"
```

### Task 2: ViewModel document state and reset logic

**Files:**
- Modify: `MobileAdmin/model/ViewModel.swift`
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Write the failing ViewModel tests**

Add tests such as:

```swift
@Test func loadSelectedPodDocuments_setsDescribeAndYAML() async
@Test func loadSelectedDeploymentDocuments_setsDescribeAndYAML() async
@Test func loadSelectedServiceDocuments_setsYAMLAndClearsDescribe() async
@Test func refreshKubernetesOverview_clearsStaleDescribeAndYAML() async
@Test func switchKubernetesContext_clearsStaleDescribeAndYAML() async
```

You will need to extend `StubKubernetesService` with raw text fields and fetch counters:

```swift
var podDescribeText: String
var deploymentDescribeText: String
var yamlText: String
```

- [ ] **Step 2: Run the targeted ViewModel suite and verify it fails**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
```

Expected: FAIL because the document state and loaders do not exist yet.

- [ ] **Step 3: Implement the minimal ViewModel changes**

Add state:

```swift
@Published var selectedDescribeText: String = ""
@Published var selectedYAMLText: String = ""
@Published var isKubernetesDocumentLoading = false
```

Add helpers:

```swift
@MainActor func resetKubernetesDocumentState()
@MainActor func loadSelectedPodDocuments() async
@MainActor func loadSelectedDeploymentDocuments() async
@MainActor func loadSelectedServiceDocuments() async
```

Rules:
- pod: describe + yaml
- deployment: describe + yaml
- service: yaml only, clear describe
- namespace/context refresh clears stale document state

- [ ] **Step 4: Re-run the targeted ViewModel tests**

Run the same command from Step 2.

Expected: targeted document-state tests pass.

- [ ] **Step 5: Commit the ViewModel slice**

```bash
git add MobileAdmin/model/ViewModel.swift MobileAdminTests/ViewModelKubernetesTests.swift
git commit -m "Add Kubernetes describe and YAML state"
```

### Task 3: Detail inspector UI

**Files:**
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift`
- Modify: `MobileAdmin/views/macos/KubernetesListViewForMac.swift`

- [ ] **Step 1: Add the mode enum and view branching**

Use a local enum if that keeps the diff smaller:

```swift
enum KubernetesInspectorMode: String, CaseIterable, Identifiable {
    case overview
    case ops
    case describe
    case yaml
    var id: String { rawValue }
}
```

- [ ] **Step 2: Implement the inspector controls and content panes**

In `KubernetesDetailViewForMac.swift`:

- add picker/tabs for inspector mode
- keep `Overview` and `Ops` aligned with existing content
- add `Describe` pane with a scrollable raw text view
- add `YAML` pane with a scrollable raw text view
- hide or disable unsupported modes depending on selected resource

Use extracted helper views/computed properties instead of one huge `body` expression.

- [ ] **Step 3: Update selection handling in the list view**

In `KubernetesListViewForMac.swift`:

- deployment selection should trigger `loadSelectedDeploymentDocuments()`
- pod selection should trigger `loadSelectedPodDocuments()`
- service selection should trigger `loadSelectedServiceDocuments()`
- ConfigMap/Secret selection should clear describe/YAML state in this slice

- [ ] **Step 4: Run the strongest available verification**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesServiceTests'
xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: targeted tests and build pass. If local Xcode is still unavailable, record the exact blocker and at least run the strongest available partial verification such as `swiftc -typecheck` for non-UI sources.

- [ ] **Step 5: Commit the UI slice**

```bash
git add MobileAdmin/views/macos/KubernetesDetailViewForMac.swift MobileAdmin/views/macos/KubernetesListViewForMac.swift
git commit -m "Show Kubernetes describe and YAML"
```
