# Kubernetes Live Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add manual refresh plus a single auto-refresh toggle for rollout status, events, and logs inside the existing macOS Kubernetes `Ops` view.

**Architecture:** Keep the existing single Kubernetes route and existing `Ops` detail pane. Add refresh orchestration in `ViewModel`, reuse the existing rollout/event/log loaders, and expose one auto-refresh loop that targets deployment operations or pod operations depending on the current selection.

**Tech Stack:** Swift, SwiftUI, Foundation, Apple Testing framework, xcodebuild, kubectl

---

## File Structure

- Modify: `MobileAdmin/model/ViewModel.swift` — auto-refresh state, cancellation, and manual refresh helpers.
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift` — auto-refresh toggle plus per-section refresh controls in `Ops` mode.
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift` — refresh orchestration and failure-state tests.

### Task 1: ViewModel refresh orchestration

**Files:**
- Modify: `MobileAdmin/model/ViewModel.swift`
- Test: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Write the failing tests for manual refresh and auto-refresh state**

Add these tests to `MobileAdminTests/ViewModelKubernetesTests.swift`:

```swift
@Test func refreshSelectedOperationsOnce_forDeployment_callsRolloutAndEvents() async
@Test func refreshSelectedOperationsOnce_forPod_callsLogsAndEvents() async
@Test func refreshSelectedOperationsOnce_forUnsupportedSelection_clearsAutoRefreshState() async
@Test func stopKubernetesAutoRefresh_turnsOffToggleAndCancelsTaskState() async
```

Extend `StubKubernetesService` with counters:

```swift
var fetchedPodLogsRequests: [(namespace: String, name: String)] = []
```

And update `fetchPodLogs`:

```swift
func fetchPodLogs(name: String, namespace: String) async throws -> String {
    if let podLogsError { throw podLogsError }
    fetchedPodLogsRequests.append((namespace, name))
    return logs
}
```

- [ ] **Step 2: Run the targeted ViewModel test suite and verify it fails**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
```

Expected: FAIL because the new refresh orchestration APIs do not exist yet.

- [ ] **Step 3: Implement the minimal `ViewModel` refresh orchestration**

Add state to `MobileAdmin/model/ViewModel.swift`:

```swift
@Published var isKubernetesAutoRefreshEnabled = false
@Published var kubernetesAutoRefreshInterval: TimeInterval = 10

private var kubernetesAutoRefreshTask: Task<Void, Never>?
```

Add helpers:

```swift
@MainActor
func stopKubernetesAutoRefresh() {
    kubernetesAutoRefreshTask?.cancel()
    kubernetesAutoRefreshTask = nil
    isKubernetesAutoRefreshEnabled = false
}

@MainActor
func refreshSelectedOperationsOnce() async {
    if selectedKubeDeployment != nil {
        await loadSelectedDeploymentOperationalDetails()
    } else if selectedKubePod != nil {
        await refreshPodLogs()
        await loadSelectedPodOperationalDetails()
    } else {
        stopKubernetesAutoRefresh()
    }
}

@MainActor
func startKubernetesAutoRefreshIfNeeded() {
    stopKubernetesAutoRefresh()
    guard isKubernetesAutoRefreshEnabled else { return }
    guard selectedKubeDeployment != nil || selectedKubePod != nil else {
        isKubernetesAutoRefreshEnabled = false
        return
    }

    kubernetesAutoRefreshTask = Task { [weak self] in
        while !Task.isCancelled {
            await self?.refreshSelectedOperationsOnce()
            try? await Task.sleep(for: .seconds(self?.kubernetesAutoRefreshInterval ?? 10))
        }
    }
}
```

Update resets so these paths call `stopKubernetesAutoRefresh()`:

- `refreshKubernetesOverview()`
- `switchKubernetesContext(to:)`
- `clearSelectedKubernetesResources()`

- [ ] **Step 4: Re-run the targeted ViewModel tests and verify they pass**

Run the same command from Step 2.

Expected: PASS for the new orchestration tests.

- [ ] **Step 5: Commit the refresh orchestration slice**

```bash
git add MobileAdmin/model/ViewModel.swift MobileAdminTests/ViewModelKubernetesTests.swift
git commit -m "Add Kubernetes auto refresh state"
```

### Task 2: Ops-mode refresh controls

**Files:**
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift`
- Modify: `MobileAdmin/model/ViewModel.swift`

- [ ] **Step 1: Add the smallest failing test if you need one more contract around toggle/reset behavior**

If the current ViewModel tests do not already cover unsupported-selection behavior or toggle reset, add one more test before touching the UI.

- [ ] **Step 2: Add auto-refresh toggle UI to `Ops` mode**

In `KubernetesDetailViewForMac.swift`, add a section near the top of `Ops` mode:

```swift
Section("Live Refresh") {
    Toggle("Auto Refresh", isOn: $viewModel.isKubernetesAutoRefreshEnabled)
        .onChange(of: viewModel.isKubernetesAutoRefreshEnabled) { _, isEnabled in
            if isEnabled {
                viewModel.startKubernetesAutoRefreshIfNeeded()
            } else {
                viewModel.stopKubernetesAutoRefresh()
            }
        }
}
```

- [ ] **Step 3: Add manual refresh buttons to supported sections**

For deployment ops:

```swift
Button("Refresh") {
    Task { await viewModel.loadSelectedDeploymentOperationalDetails() }
}
```

For pod logs:

```swift
Button("Refresh") {
    Task { await viewModel.refreshPodLogs() }
}
```

For pod/deployment events:

```swift
Button("Refresh") {
    Task { await viewModel.refreshSelectedOperationsOnce() }
}
```

- [ ] **Step 4: Re-run the targeted ViewModel tests and a project build**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS. If local Xcode is still unavailable, record the exact blocker and at least re-run the strongest available partial verification.

- [ ] **Step 5: Commit the UI controls slice**

```bash
git add MobileAdmin/views/macos/KubernetesDetailViewForMac.swift MobileAdmin/model/ViewModel.swift
git commit -m "Add Kubernetes live refresh controls"
```

### Task 3: Selection and lifecycle reset hardening

**Files:**
- Modify: `MobileAdmin/views/macos/KubernetesListViewForMac.swift`
- Modify: `MobileAdmin/model/ViewModel.swift`
- Test: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Write the failing reset tests for selection changes**

Add tests such as:

```swift
@Test func clearSelectedKubernetesResources_stopsAutoRefresh() async
@Test func switchKubernetesContext_stopsAutoRefresh() async
@Test func refreshKubernetesOverview_stopsAutoRefresh() async
```

- [ ] **Step 2: Run the targeted ViewModel suite and verify it fails**

Run the same targeted ViewModel test command.

Expected: FAIL until the reset paths stop the active loop consistently.

- [ ] **Step 3: Make the smallest reset changes**

Ensure these paths call `stopKubernetesAutoRefresh()` exactly once and leave toggle/task state coherent:

- list selection changes to unsupported resources
- namespace changes
- context changes
- explicit resource clearing

In `KubernetesListViewForMac.swift`, after selecting service/configmap/secret, ensure unsupported auto-refresh state is stopped/reset rather than left on.

- [ ] **Step 4: Re-run the strongest available verification**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
xcodebuild analyze -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS. If local Xcode remains unavailable, document the exact blocker and keep the strongest available partial verification in the report.

- [ ] **Step 5: Commit the reset-hardening slice**

```bash
git add MobileAdmin/model/ViewModel.swift MobileAdmin/views/macos/KubernetesListViewForMac.swift MobileAdminTests/ViewModelKubernetesTests.swift
git commit -m "Harden Kubernetes live refresh reset"
```
