# Kubernetes Action Safety and Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add stronger confirmation, persistent local audit logging, and rollback guidance for the existing Kubernetes mutating actions.

**Architecture:** Keep the current Kubernetes action UI in place, but route scale / rollout restart / delete pod through a centralized action-safety wrapper in `ViewModel`. Persist action results in a SwiftData-backed audit model that is local-only for now but export-friendly later, and surface both confirmation context and rollback/next-step guidance in the macOS detail pane.

**Tech Stack:** Swift, SwiftUI, SwiftData, Foundation, Apple Testing framework, xcodebuild, kubectl

---

## File Structure

- Create: `MobileAdmin/model/DevTools/KubernetesActionAuditEntry.swift` — SwiftData model for persistent local audit entries.
- Modify: `MobileAdmin/MobileAdminApp.swift` — register the new audit model in the shared SwiftData schema.
- Modify: `MobileAdmin/model/ViewModel.swift` — action wrapper, confirmation state, audit persistence, and rollback guidance generation.
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift` — structured confirmation UX, result summary, and local audit history surface.
- Create or modify: `MobileAdminTests/KubernetesActionAuditTests.swift` — audit entry / rollback guidance tests.
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift` — action wrapper, cancellation, and persistence-oriented tests.

### Task 1: Persistent audit model and schema wiring

**Files:**
- Create: `MobileAdmin/model/DevTools/KubernetesActionAuditEntry.swift`
- Modify: `MobileAdmin/MobileAdminApp.swift`
- Test: `MobileAdminTests/KubernetesActionAuditTests.swift`

- [ ] **Step 1: Write the failing audit model tests**

Create `MobileAdminTests/KubernetesActionAuditTests.swift` with tests such as:

```swift
@Test func scaleAuditEntry_preservesPreviousAndRequestedReplicaCounts()
@Test func cancelledAuditEntry_marksResultAsCancelled()
@Test func rollbackGuidance_forScaleUsesPreviousReplicaCount()
```

Use explicit model construction expectations instead of persistence first.

- [ ] **Step 2: Run the targeted audit test suite and verify it fails**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesActionAuditTests'
```

Expected: FAIL because the audit model does not exist yet.

- [ ] **Step 3: Implement the minimal persistent audit model**

Create `MobileAdmin/model/DevTools/KubernetesActionAuditEntry.swift` with a SwiftData `@Model` plus lightweight enums/fields, for example:

```swift
import Foundation
import SwiftData

enum KubernetesActionType: String, Codable {
    case scale
    case rolloutRestart
    case deletePod
}

enum KubernetesActionResult: String, Codable {
    case success
    case failure
    case cancelled
}

@Model
final class KubernetesActionAuditEntry {
    var timestamp: Date
    var actionTypeRaw: String
    var resourceKind: String
    var resourceName: String
    var namespace: String
    var requestedValue: String?
    var previousValue: String?
    var resultRaw: String
    var errorSummary: String?
    var rollbackGuidance: String
    var actorLabel: String

    init(...) { ... }
}
```

Update `MobileAdminApp.swift` schema registration to include `KubernetesActionAuditEntry.self`.

- [ ] **Step 4: Re-run the targeted audit tests**

Run the same command from Step 2.

Expected: the targeted model tests pass.

- [ ] **Step 5: Commit the audit model slice**

```bash
git add MobileAdmin/model/DevTools/KubernetesActionAuditEntry.swift MobileAdmin/MobileAdminApp.swift MobileAdminTests/KubernetesActionAuditTests.swift
git commit -m "Add Kubernetes action audit model"
```

### Task 2: Action wrapper and rollback guidance in ViewModel

**Files:**
- Modify: `MobileAdmin/model/ViewModel.swift`
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Write the failing ViewModel action-wrapper tests**

Add tests covering:

```swift
@Test func performScaleAction_recordsSuccessAuditWithRollbackGuidance() async
@Test func performRolloutRestartAction_recordsFailureAudit() async
@Test func cancelDeletePodAction_recordsCancelledAuditEntry() async
```

Use a stubbed persistence sink or temporary in-memory context seam if needed; do not make these tests depend on full app startup.

- [ ] **Step 2: Run the targeted ViewModel suite and verify it fails**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
```

Expected: FAIL because the action wrapper, cancellation logging, and rollback guidance do not exist yet.

- [ ] **Step 3: Implement the minimal centralized action wrapper**

In `ViewModel`, add state for:

```swift
@Published var pendingKubernetesActionSummary: String?
@Published var latestKubernetesActionGuidance: String?
@Published var latestKubernetesActionResult: String?
```

Add an execution wrapper pattern that:

- builds a summary for confirmation
- executes the existing action call
- records a `KubernetesActionAuditEntry`
- sets rollback/next-step guidance text

For rollback guidance:

- scale: include previous replicas when known
- rollout restart: no direct undo; point to rollout status/events
- delete pod: no direct undo; only conditional controller-recreation guidance

- [ ] **Step 4: Re-run the targeted ViewModel tests**

Run the same command from Step 2.

Expected: targeted action-wrapper tests pass.

- [ ] **Step 5: Commit the ViewModel safety slice**

```bash
git add MobileAdmin/model/ViewModel.swift MobileAdminTests/ViewModelKubernetesTests.swift
git commit -m "Add Kubernetes action safety wrapper"
```

### Task 3: macOS confirmation and audit history UI

**Files:**
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift`
- Modify: `MobileAdmin/model/ViewModel.swift`

- [ ] **Step 1: Add the smallest extra failing test if the UI contract needs one**

If you need one more ViewModel-level contract for confirmation/cancellation result state, add it before editing the view.

- [ ] **Step 2: Replace ad-hoc action buttons with structured confirmation flow**

Update `KubernetesDetailViewForMac.swift` so:

- delete pod uses a stronger 2-step confirmation flow with summary text
- scale confirmation shows previous and target replicas when available
- rollout restart confirmation clearly identifies target deployment/namespace

- [ ] **Step 3: Add audit history display**

Add a local audit history section or inspector pane showing recent entries with:

- timestamp
- action
- resource
- result
- rollback guidance summary

Keep the first slice read-only.

- [ ] **Step 4: Run the strongest available verification**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesActionAuditTests'
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: targeted tests and build pass. If local Xcode remains unavailable, document the exact blocker and still run the strongest available partial verification.

- [ ] **Step 5: Commit the UI slice**

```bash
git add MobileAdmin/views/macos/KubernetesDetailViewForMac.swift MobileAdmin/model/ViewModel.swift
git commit -m "Show Kubernetes action audit history"
```
