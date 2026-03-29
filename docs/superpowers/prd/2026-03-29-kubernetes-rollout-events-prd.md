# Kubernetes Rollout Status and Events PRD

## Summary

Extend the macOS Kubernetes workspace so an operator can inspect deployment rollout status and resource-related events from the existing detail pane without switching to Terminal.

## Problem

The current Kubernetes feature can browse resources and perform a few operational actions, but it does not yet expose the most common read-only operational signals after those actions. An operator still needs Terminal to answer questions like "is this rollout progressing?" and "what events are attached to this resource?"

## Goal

Add read-only operational visibility for `rollout status` and `events` to the existing macOS Kubernetes detail experience.

## Target User

- A macOS operator already using the app's kubectl-backed Kubernetes screen
- A user who needs fast operational feedback after selecting a deployment or other Kubernetes resource

## In Scope

- macOS-only enhancement to the existing Kubernetes feature
- Deployment `rollout status` display in the detail pane
- Resource-related `events` display in the detail pane
- Events support for selected resources in the current Kubernetes screen, including at least deployments and pods, with the same infrastructure reusable for other selected resource kinds already shown in the UI
- Loading and error state handling for these read-only operational queries
- Resetting stale rollout/event state when selection or namespace/context changes

## Out of Scope

- New sidebar routes or separate Kubernetes screens
- Automatic polling or watch streaming
- `describe` output
- Log streaming changes
- New mutating Kubernetes actions

## User Stories

1. As a macOS operator, when I select a deployment, I can see rollout status in the detail pane.
2. As a macOS operator, when I select a resource, I can see related Kubernetes events in the detail pane.
3. As a macOS operator, I receive a clear error or empty state when rollout/event data cannot be loaded.

## Success Criteria

- The existing Kubernetes detail pane shows rollout status for selected deployments.
- The existing Kubernetes detail pane shows resource-related events for selected resources.
- The UI never hangs indefinitely while waiting for rollout status.
- Stale rollout or event results are cleared when the selected resource or namespace/context changes.

## Constraints

- Follow the current architecture: `ViewModel` facade plus `KubernetesService`.
- Keep this as a narrow extension of the existing single Kubernetes route.
- Use Apple frameworks already in the repo.

## Risks

- `kubectl rollout status` can block longer than a desktop detail view should tolerate if not bounded.
- `kubectl get events` payloads vary by cluster version and can be noisy.
- Resource-event filtering can be misleading if the involved object fields are parsed incorrectly.

## Acceptance Criteria

- Selecting a deployment loads rollout status into the existing detail pane.
- Selecting a deployment or pod shows filtered related events in the existing detail pane.
- Namespace or context changes clear outdated rollout/event state before reloading.
- Failures are surfaced clearly and do not expose unsupported operations.
