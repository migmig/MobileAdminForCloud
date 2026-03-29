# Kubernetes Describe and YAML Design

**Date:** 2026-03-29  
**Status:** Approved for planning  
**Platform:** macOS only

## Goal

Add read-only `describe` and YAML inspection to the existing macOS Kubernetes detail pane for pods, deployments, and services.

## Chosen Approach

Keep the existing single `.sourceKubernetes` route and refactor the detail pane into an internal inspector with display modes rather than continuing to append long sections to one scroll view.

Recommended display modes:

- `Overview`
- `Ops`
- `Describe`
- `YAML`

## Why This Approach

The current Kubernetes detail pane is already accumulating multiple resource-specific sections. Adding raw `describe` and YAML text directly as more sections would increase SwiftUI view-builder complexity and reduce usability. A mode-based inspector keeps the route stable while letting the detail pane scale into a deeper operations surface.

## Functional Scope

### Describe support

- pod describe
- deployment describe

### YAML support

- pod YAML
- deployment YAML
- service YAML

### Explicit exclusions

- no YAML editing or apply
- no service describe in this slice
- no ConfigMap/Secret YAML in this slice
- no new routes or windows

## Architecture

### 1. Service layer additions

Extend `KubernetesService` with fixed-function raw text APIs:

- `fetchPodDescribe(name:namespace:) -> String`
- `fetchDeploymentDescribe(name:namespace:) -> String`
- `fetchResourceYAML(kind:name:namespace:) -> String`

The service should use bounded, fixed command construction only:

- `kubectl describe pod <name> -n <namespace>`
- `kubectl describe deployment <name> -n <namespace>`
- `kubectl get <kind> <name> -n <namespace> -o yaml`

### 2. ViewModel additions

Add raw document state:

- `selectedDescribeText`
- `selectedYAMLText`
- `isKubernetesDocumentLoading`

Add resource-aware loaders:

- pod selection loads pod describe + pod YAML
- deployment selection loads deployment describe + deployment YAML
- service selection loads service YAML and clears describe

Add a reset helper so resource, namespace, and context changes clear stale document text before fetching again.

### 3. Detail-pane display mode

`KubernetesDetailViewForMac` should use an internal mode state, for example:

```swift
enum KubernetesInspectorMode {
    case overview
    case ops
    case describe
    case yaml
}
```

Behavior:

- `Overview` shows current summary/detail information
- `Ops` shows actions, rollout, events, logs
- `Describe` is shown only when supported for the selected resource
- `YAML` is shown only when supported for the selected resource

### 4. UI rules by resource type

- **Pod**
  - Overview: yes
  - Ops: yes
  - Describe: yes
  - YAML: yes

- **Deployment**
  - Overview: yes
  - Ops: yes
  - Describe: yes
  - YAML: yes

- **Service**
  - Overview: yes
  - Ops: existing read-only summary only
  - Describe: no
  - YAML: yes

- **ConfigMap / Secret**
  - No new support in this slice; existing views remain unchanged

## Data Flow

1. User selects a supported Kubernetes resource.
2. Existing selection state updates in the list/detail workflow.
3. `ViewModel` clears stale describe/YAML text.
4. `ViewModel` calls the corresponding `KubernetesService` raw text loader.
5. Service runs the fixed kubectl command.
6. `ViewModel` publishes the resulting describe/YAML text.
7. Detail pane renders the selected mode.

## Error Handling

Minimum cases:

- describe command failure
- yaml command failure
- unsupported resource/mode combination
- selection/context/namespace switch during loading

Rules:

- clear stale text before starting a new fetch
- use explicit empty/error states, not retained old data
- reuse the existing Kubernetes error display channel for failures
- hide or disable unsupported modes instead of showing blank content with no explanation

## Testing Strategy

### Unit tests

- `KubernetesServiceTests`
  - pod describe command arguments
  - deployment describe command arguments
  - resource YAML command arguments
  - returned raw text trimming/retention behavior

- `ViewModelKubernetesTests`
  - pod selection loads describe + YAML
  - deployment selection loads describe + YAML
  - service selection clears describe and loads YAML only
  - stale describe/YAML content is cleared on resource switch, namespace change, and context change

### Manual verification

On a macOS machine with working kubectl:

1. Select a pod and verify Describe and YAML modes both show content.
2. Select a deployment and verify Describe and YAML modes both show content.
3. Select a service and verify YAML is available while Describe is hidden/disabled.
4. Switch resource and namespace/context and verify old describe/YAML content does not remain visible.

## Incremental Delivery

1. Add `KubernetesService` describe/YAML APIs.
2. Add `ViewModel` document state and reset/load helpers.
3. Refactor `KubernetesDetailViewForMac` into a mode-based inspector.
4. Add focused tests for resource support and stale-state reset.

## Non-Goals for This Spec

This spec does not add YAML editing, YAML apply, service describe, or ConfigMap/Secret YAML. Those can be layered later on the same inspector pattern.
