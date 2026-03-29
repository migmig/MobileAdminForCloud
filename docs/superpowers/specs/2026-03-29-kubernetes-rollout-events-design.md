# Kubernetes Rollout Status and Events Design

**Date:** 2026-03-29  
**Status:** Approved for planning  
**Platform:** macOS only

## Goal

Add read-only rollout status and Kubernetes events to the existing macOS Kubernetes detail pane so an operator can inspect operational state without leaving the app.

## Chosen Approach

Extend the existing `KubernetesDetailViewForMac` rather than adding new routes or screens.

This preserves the current interaction model:

- select a resource in the Kubernetes list pane
- inspect resource details in the existing detail pane
- show operational read-only sections only when relevant to the selected resource

## Why This Approach

The branch already has a single `.sourceKubernetes` route with list/detail behavior. Adding rollout status and events to that detail pane is the smallest, most consistent extension. It avoids route churn, keeps the diff narrow, and leaves room for future `describe` support in the same detail structure.

## Functional Scope

### Read operations

- deployment rollout status
- resource-related events

### Resource coverage

- rollout status: deployments only
- events: deployments and pods in the initial slice, with service-layer filtering reusable for the other resource kinds already present in the Kubernetes screen

### Explicit exclusions

- no new sidebar categories
- no watch mode / polling loop
- no `describe` output in this slice
- no new mutating operations

## Architecture

### 1. Service layer additions

Extend `KubernetesService` with two read-only APIs:

- `fetchRolloutStatus(deployment:namespace:) -> String`
- `fetchEvents(namespace:resourceKind:resourceName:) -> [KubernetesEventInfo]`

#### Rollout status

The service should invoke `kubectl rollout status deployment/<name> -n <namespace>` using a bounded execution strategy suitable for a UI-triggered detail view. The command must not be allowed to wait indefinitely; if the command times out or otherwise fails, the service should surface a readable failure through the existing error pathway rather than leaving the detail pane hanging.

#### Events

The service should retrieve namespace events via `kubectl get events -n <namespace> -o json`, decode the minimal fields needed for display, and filter the results against the selected resource using involved-object metadata.

Minimal decoded fields:

- event type
- reason
- message
- involved object kind
- involved object name
- event timestamp string

### 2. Model additions

Add a focused event model, for example `KubernetesEventInfo`, containing only the fields needed for list display and filtering.

The event model should remain read-only and display-oriented rather than mirroring the full Kubernetes event schema.

### 3. ViewModel additions

Extend `ViewModel` with read-only operational state:

- `kubeEvents: [KubernetesEventInfo]`
- `selectedRolloutStatus: String`
- `isKubernetesActionLoading: Bool`

Behavior rules:

- selecting a deployment loads rollout status and events
- selecting a pod loads events only
- namespace/context refresh clears stale rollout status, events, and incompatible selections before repopulating
- failures set the existing Kubernetes error state and leave the UI in a recoverable empty state

### 4. macOS detail UI additions

Extend `KubernetesDetailViewForMac` with two new read-only sections.

#### Rollout Status section

- shown only when a deployment is selected
- text-oriented presentation
- clear empty/error handling

#### Events section

- shown when the selected resource has event support in this slice
- compact list of recent events
- each row shows type, reason, timestamp, and message

The UI remains in the current detail pane and should not add new navigation structure.

## Data Flow

1. User selects a deployment or pod in the Kubernetes list pane.
2. The selection updates the existing detail context.
3. `ViewModel` triggers the corresponding read-only operational fetch.
4. `KubernetesService` executes bounded rollout status or event retrieval through `KubectlRunner`.
5. Service decodes and filters the result.
6. `ViewModel` publishes rollout/event state.
7. `KubernetesDetailViewForMac` renders the new sections.

## Error Handling

Minimum cases:

- rollout status command failure or timeout
- event decode failure
- no related events found
- resource changes during refresh

Rules:

- failures should use existing Kubernetes error presentation
- rollout and event content should reset when becoming stale
- empty results should use explicit empty states rather than silently showing old data

## Testing Strategy

### Unit tests

- `KubernetesServiceTests`
  - rollout status returns text from the runner
  - events JSON decodes correctly
  - event filtering keeps only matching resource events
- `ViewModelKubernetesTests`
  - deployment selection loads rollout status and events
  - pod selection loads events without rollout status
  - namespace/context refresh clears stale rollout/event state

### Manual verification

On a macOS machine with working kubectl:

1. Select a deployment and verify rollout status appears.
2. Select the same deployment and verify matching events appear.
3. Select a pod and verify events appear while rollout status does not.
4. Change namespace/context and verify old rollout/event content clears before new content appears.

## Incremental Delivery

1. Add event model and service APIs.
2. Add `ViewModel` rollout/event state and reset behavior.
3. Extend `KubernetesDetailViewForMac` with rollout and events sections.
4. Add focused tests and manual verification notes.

## Non-Goals for This Spec

This spec does not include `pod describe`, `deployment describe`, or `service describe`. Those can be layered on the same detail-pane pattern later.
