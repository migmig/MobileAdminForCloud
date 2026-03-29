# macOS kubectl Kubernetes Integration Design

**Date:** 2026-03-29  
**Status:** Approved for planning  
**Platform:** macOS only

## Goal

Integrate a macOS-only Kubernetes feature into MobileAdminForCloud that uses the host machine's installed `kubectl` for safe, constrained cluster inspection and basic operational control.

## Chosen Approach

Use a fixed-feature `kubectl` wrapper, not a freeform command runner.

This matches the current repository structure best:

- UI stays in the existing SwiftUI DevTools area
- `ViewModel` remains the observable facade
- Kubernetes-specific logic lives in a dedicated service layer
- local process execution is isolated behind a small runner abstraction

## Why This Approach

This repository already favors service-based feature access such as `BuildService`, `PipelineService`, and `DeployService`. A Kubernetes feature should follow that same model instead of introducing a broad terminal-execution system. A constrained wrapper also reduces accidental destructive behavior and keeps testing practical.

## Functional Scope

### Read operations

- detect `kubectl` availability
- get current context
- get available contexts
- switch context
- list namespaces
- list pods for selected namespace
- list deployments for selected namespace
- list services for selected namespace
- list config maps for selected namespace
- list secrets for selected namespace
- fetch logs for selected pod

### Write/operation actions

- scale deployment
- rollout restart deployment
- delete pod

### Explicit exclusions

- no arbitrary `kubectl` command text box
- no iOS support
- no Helm
- no `exec`, `port-forward`, `apply`, or manifest editing
- no live watch/stream mode in the first release

## Architecture

### 1. Kubectl runner layer

Create a small macOS-only runner responsible for local process execution.

Responsibilities:

- locate and run `kubectl`
- pass allowed arguments only
- capture stdout, stderr, and exit code
- normalize execution failures into typed errors

Suggested shape:

- `KubectlRunning` protocol
- `KubectlRunner` concrete implementation
- `KubectlCommandResult` value type
- `KubernetesCommandError` typed error enum

This layer should not know about SwiftUI views.

### 2. Kubernetes service layer

Add a dedicated `KubernetesService` under `MobileAdmin/model/services/`.

Responsibilities:

- expose fixed operations such as `fetchContexts()`, `fetchNamespaces()`, `fetchPods(namespace:)`, `scaleDeployment(...)`
- build only approved argument sets
- decode JSON outputs into strongly typed models when possible
- map command failures into domain-friendly errors for the view model

Where practical, read commands should prefer `-o json` and `Codable` models. Log retrieval can remain plain text.

For these additional resources, prefer the following safe/stable fields:

- Services: `metadata.name`, `spec.type`, `spec.clusterIPs` or `spec.clusterIP`, `spec.externalName`, `spec.ports`, `status.loadBalancer.ingress`
- ConfigMaps: `metadata.name`, `immutable`, `data` keys/count, `binaryData` keys/count
- Secrets: `metadata.name`, `type`, `immutable`, `data` keys/count

Secret values must not be shown by default. The safe default is metadata plus key names/count only.

### 3. ViewModel integration

Extend `ViewModel` with Kubernetes-specific observable state and thin forwarding methods.

Expected state shape:

- `kubeContexts`
- `selectedKubeContext`
- `kubeNamespaces`
- `selectedKubeNamespace`
- `kubePods`
- `kubeDeployments`
- `kubeServices`
- `kubeConfigMaps`
- `kubeSecrets`
- `selectedKubeService`
- `selectedKubeConfigMap`
- `selectedKubeSecret`
- `selectedPodLogs`
- `kubernetesError`
- `isKubernetesLoading`

The `ViewModel` should delegate all real work to `KubernetesService`, matching the repository's newer pattern.

### 4. macOS UI integration

Add a Kubernetes entry point in the macOS DevTools navigation and keep the first UI focused on operator workflows.

Suggested layout:

- toolbar/header:
  - kubectl availability status
  - context picker
  - namespace picker
  - refresh action
- primary content:
  - pods list
  - deployments list
  - services list
  - config maps list
  - secrets list
- detail/actions area:
  - pod logs viewer
  - deployment scale action
  - rollout restart action
  - pod delete action with confirmation
  - service detail summary
  - config map key/value detail
  - secret metadata plus key names only by default

The UI should be macOS-only and should not force new patterns onto iOS files.

## Data Flow

1. User opens the Kubernetes screen on macOS.
2. View requests kubectl availability and current context through `ViewModel`.
3. `ViewModel` calls `KubernetesService`.
4. `KubernetesService` uses `KubectlRunner` to execute a constrained `kubectl` command.
5. The runner returns stdout/stderr/exit code.
6. The service decodes or maps the result.
7. `ViewModel` publishes state updates.
8. The view refreshes lists, logs, and action status.

## Error Handling

Errors need to be user-readable and operationally useful.

Minimum cases:

- `kubectl` not installed
- `kubectl` not reachable from the app environment
- kubeconfig missing or invalid
- context missing or inaccessible
- namespace/resource not found
- command returns non-zero exit code
- JSON decode failure for a supported read command
- secret parsing/display path accidentally exposing sensitive values

Design rules:

- Preserve stderr details when they help the user.
- Convert low-level failures into typed errors.
- Show destructive-action failures inline near the action result when possible.
- Require confirmation before `delete pod`.

## Security and Safety Boundaries

- The first release does not allow arbitrary command execution.
- Only predetermined operations are exposed in the UI.
- Actions that mutate cluster state must be explicit and user-initiated.
- The app relies on the host's existing Kubernetes credentials and does not store new credentials.
- Secret values are not auto-decoded or auto-rendered in the default UI.

## File Placement

Expected new or changed areas:

- `MobileAdmin/model/services/`
  - `KubernetesService.swift`
  - `KubectlRunner.swift`
  - `KubernetesCommandError.swift`
- `MobileAdmin/model/DevTools/`
  - Kubernetes response/resource models for contexts, namespaces, pods, deployments, services, config maps, secrets
- `MobileAdmin/model/ViewModel.swift`
  - observable state + forwarding methods
- `MobileAdmin/views/macos/` and/or `MobileAdmin/views/common/devTools/`
  - macOS Kubernetes list/detail views
- `MobileAdminTests/`
  - runner/service/viewmodel tests using test doubles

Final file names can adapt to nearby repository naming patterns during planning.

## Testing Strategy

### Unit tests

- runner result mapping from process output to typed result/error
- service decoding of JSON fixtures for contexts, namespaces, pods, deployments, services, config maps, secrets
- service command construction for scale/restart/delete actions
- view model state update behavior for success and failure paths

### Integration boundary strategy

Do not require real cluster access in normal automated tests. Instead, abstract the runner behind a protocol and inject a fake implementation.

### Manual verification

When implemented, verify on a macOS machine with:

- working `kubectl`
- at least one context
- at least one namespace with pods/deployments
- confirmation that supported actions behave correctly and errors are understandable

## Incremental Delivery

Recommended implementation order:

1. runner + typed errors
2. read-only flows: availability, contexts, namespaces, pods, deployments, services, config maps, secrets, logs
3. mutating actions: scale, restart, delete with confirmation
4. UI polish and empty/error states

## Open Decisions Already Resolved

- Platform: macOS only
- Execution model: use local host `kubectl`
- Feature scope: read operations for pods, deployments, services, config maps, and safe secret views, plus scale / rollout restart / pod delete
- Safety model: fixed-function wrapper, not arbitrary shell access

## Non-Goals for This Spec

This document does not define the task-by-task implementation breakdown. That belongs in the planning stage after spec review.
