# Kubernetes ConfigMap and Secret YAML Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add ConfigMap YAML and Secret raw YAML to the existing Kubernetes inspector, with Secret-specific key reveal/copy support inside YAML mode.

**Architecture:** Reuse the existing `fetchResourceYAML(kind:name:namespace:)` service path and existing YAML inspector mode. Extend `ViewModel` with ConfigMap/Secret-specific document loaders, then render ConfigMap and Secret cases in the current `YAML` mode while reusing the existing Secret key reveal/copy safety helpers.

**Tech Stack:** Swift, SwiftUI, Foundation, Apple Testing framework, xcodebuild, kubectl

---

## File Structure

- Modify: `MobileAdmin/model/ViewModel.swift` — add ConfigMap/Secret YAML document loaders.
- Modify: `MobileAdmin/views/macos/KubernetesListViewForMac.swift` — trigger ConfigMap/Secret YAML loading from selection changes.
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift` — allow ConfigMap/Secret YAML mode and show Secret YAML warning + key reveal/copy panel.
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift` — add ConfigMap/Secret YAML loading and reset tests.
- Optional: `MobileAdminTests/KubernetesResourceInfoTests.swift` only if a new Secret helper becomes necessary.

### Task 1: ViewModel document-loading support

**Files:**
- Modify: `MobileAdmin/model/ViewModel.swift`
- Modify: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Write the failing ViewModel tests**

Add tests:

```swift
@Test func loadSelectedConfigMapDocuments_setsYAMLAndClearsDescribe() async
@Test func loadSelectedSecretDocuments_setsYAMLAndClearsDescribe() async
@Test func clearSelectedKubernetesResources_clearsStaleConfigMapOrSecretYAML() async
```

Use the existing `StubKubernetesService.resourceYAMLText` seam and selected resource state.

- [ ] **Step 2: Run the targeted ViewModel test suite and verify it fails**

Run:

```bash
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
```

Expected: FAIL because ConfigMap/Secret document loaders do not exist yet.

- [ ] **Step 3: Implement the minimal ViewModel loaders**

Add to `ViewModel.swift`:

```swift
@MainActor
func loadSelectedConfigMapDocuments() async {
    guard let selectedKubeConfigMap else {
        resetKubernetesDocumentState()
        return
    }

    isKubernetesDocumentLoading = true
    defer { isKubernetesDocumentLoading = false }
    resetKubernetesDocumentState()

    do {
        selectedYAMLText = try await kubernetesService.fetchResourceYAML(kind: "configmap", name: selectedKubeConfigMap.name, namespace: selectedKubeNamespace)
        kubernetesError = nil
    } catch {
        resetKubernetesDocumentState()
        kubernetesError = error.localizedDescription
    }
}

@MainActor
func loadSelectedSecretDocuments() async {
    guard let selectedKubeSecret else {
        resetKubernetesDocumentState()
        return
    }

    isKubernetesDocumentLoading = true
    defer { isKubernetesDocumentLoading = false }
    resetKubernetesDocumentState()

    do {
        selectedYAMLText = try await kubernetesService.fetchResourceYAML(kind: "secret", name: selectedKubeSecret.name, namespace: selectedKubeNamespace)
        kubernetesError = nil
    } catch {
        resetKubernetesDocumentState()
        kubernetesError = error.localizedDescription
    }
}
```

- [ ] **Step 4: Re-run the targeted ViewModel tests**

Run the same command from Step 2.

Expected: the new ViewModel tests pass.

- [ ] **Step 5: Commit the ViewModel slice**

```bash
git add MobileAdmin/model/ViewModel.swift MobileAdminTests/ViewModelKubernetesTests.swift
git commit -m "Add ConfigMap and Secret YAML state"
```

### Task 2: Selection wiring and YAML inspector UI

**Files:**
- Modify: `MobileAdmin/views/macos/KubernetesListViewForMac.swift`
- Modify: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift`

- [ ] **Step 1: Wire ConfigMap/Secret selections to the new loaders**

In `KubernetesListViewForMac.swift`:

- ConfigMap selection should call `loadSelectedConfigMapDocuments()`
- Secret selection should call `loadSelectedSecretDocuments()`
- preserve current reset behavior for stale operational/document state

- [ ] **Step 2: Extend YAML mode support in the detail pane**

In `KubernetesDetailViewForMac.swift`:

- update `selectedResourceSupportsYAML` to include ConfigMap and Secret
- keep `selectedResourceSupportsDescribe` unchanged
- in `inspectorMode == .yaml`, render:
  - ConfigMap: existing raw YAML text view
  - Secret: existing raw YAML text view + warning text + key reveal/copy panel

- [ ] **Step 3: Reuse Secret reveal/copy helpers in YAML mode**

Do not invent a second secret-reveal source of truth. Reuse:

- `revealedSecretKeys`
- `toggleReveal(for:)`
- `copySecretValue(_:key:)`
- `SecretKeyRow`

The Secret YAML panel should clearly warn that raw YAML includes encoded values.

- [ ] **Step 4: Run the strongest available verification**

Run:

```bash
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: targeted tests and build pass.

- [ ] **Step 5: Commit the UI slice**

```bash
git add MobileAdmin/views/macos/KubernetesListViewForMac.swift MobileAdmin/views/macos/KubernetesDetailViewForMac.swift
git commit -m "Show ConfigMap and Secret YAML"
```
