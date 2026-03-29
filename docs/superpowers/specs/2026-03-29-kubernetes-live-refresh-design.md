# Kubernetes Live Refresh Design

**Date:** 2026-03-29  
**Status:** Approved for planning  
**Platform:** macOS only

## Goal

Add manual refresh and a single auto-refresh toggle for rollout status, events, and logs inside the existing macOS Kubernetes detail pane.

## Chosen Approach

Keep the current single Kubernetes route and current detail inspector. Add one auto-refresh toggle in the `Ops` mode plus per-section manual refresh actions, with the active refresh targets determined by the currently selected resource type.

## Why This Approach

The current branch already concentrates operational information inside the detail pane. A single toggle plus per-section refresh buttons gives users better liveness without introducing a new background polling subsystem or a route-level watch surface. It keeps the implementation focused, testable, and aligned with the existing selection-driven data flow.

## Functional Scope

### Manual refresh

- rollout status refresh
- events refresh
- logs refresh

### Auto-refresh

- deployment selection: refresh rollout status and events
- pod selection: refresh events and logs

### Explicit exclusions

- no true streaming logs
- no namespace-wide refresh in this slice
- no describe/YAML auto-refresh in this slice
- no refresh for unsupported resource kinds

## Architecture

### 1. ViewModel refresh orchestration

Add refresh orchestration state to `ViewModel`:

- `isKubernetesAutoRefreshEnabled`
- `kubernetesAutoRefreshInterval` (fixed default, such as 10 seconds, is acceptable in this slice)
- internal task handle for the currently running auto-refresh loop

Add helpers such as:

- `startKubernetesAutoRefreshIfNeeded()`
- `stopKubernetesAutoRefresh()`
- `refreshSelectedDeploymentOperations()`
- `refreshSelectedPodOperations()`
- `refreshSelectedOperationsOnce()`

Rules:

- only one refresh task may exist at a time
- enabling auto-refresh with no supported selected resource should be a no-op or immediately disable itself
- resource, namespace, and context changes must stop the old refresh loop before any new one starts

### 2. Reuse existing loaders

Do not introduce parallel operational loading paths if the existing ones can be reused.

- deployment path should reuse rollout/events loading already present in the branch
- pod path should reuse events/logs loading already present in the branch

If a small coordinating helper is needed, it should call those existing methods rather than re-implementing kubectl fetch logic.

### 3. Detail-pane UI

Extend the current `Ops` mode in `KubernetesDetailViewForMac` with:

- one auto-refresh toggle near the top of the mode
- manual refresh button(s) on rollout status, events, and logs sections

Behavior by resource type:

- **Deployment**
  - manual refresh: rollout status, events
  - auto-refresh: rollout status + events

- **Pod**
  - manual refresh: events, logs
  - auto-refresh: events + logs

- **Service / ConfigMap / Secret**
  - no auto-refresh in this slice
  - no misleading refresh controls for unsupported sections

### 4. Reset and lifecycle rules

The following must stop or reset active refresh behavior:

- context change
- namespace change
- selected resource change
- leaving the detail context or switching to an unsupported resource type

If the auto-refresh loop is stopped, the toggle state should remain coherent with the actual task state.

## Data Flow

1. User selects a deployment or pod.
2. User enters `Ops` mode.
3. User either taps a manual refresh control or enables the auto-refresh toggle.
4. `ViewModel` runs the correct operational refresh path for the selected resource.
5. Existing service calls update rollout status, events, and/or logs.
6. Selection or context changes stop the old refresh task and clear stale operational state as needed.

## Error Handling

Minimum cases:

- rollout refresh failure
- event refresh failure
- log refresh failure
- auto-refresh loop still active when selection becomes unsupported
- repeated refresh task creation due to toggle or selection churn

Rules:

- use the existing Kubernetes error channel for refresh failures
- do not leave multiple refresh loops running concurrently
- on failure, preserve honest loading/toggle state rather than implying refresh is still healthy

## Testing Strategy

### Unit tests

- `ViewModelKubernetesTests`
  - deployment manual refresh path calls rollout/events loaders
  - pod manual refresh path calls logs/events loaders
  - enabling auto-refresh with unsupported selection does not start a useful loop
  - selection/context/namespace changes stop/reset auto-refresh state
  - refresh helpers do not leave loading state stuck on failure

### Manual verification

On a macOS machine with working kubectl:

1. Select a deployment and verify rollout status/events manual refresh works.
2. Enable auto-refresh on a deployment and verify rollout/events update repeatedly.
3. Select a pod and verify events/logs manual refresh works.
4. Enable auto-refresh on a pod and verify events/logs update repeatedly.
5. Switch to service/configmap/secret and verify unsupported auto-refresh behavior stops or remains inactive.
6. Change namespace/context and verify stale refresh activity stops.

## Incremental Delivery

1. Add `ViewModel` auto-refresh state and cancellation helpers.
2. Add manual refresh helper methods for deployment and pod operational data.
3. Add `Ops` mode UI controls.
4. Add focused tests for cancellation/reset and failure-state handling.

## Non-Goals for This Spec

This spec does not add Kubernetes watch APIs, namespace-wide refresh, or log streaming. Those can be layered later if this polling-based slice proves useful.
