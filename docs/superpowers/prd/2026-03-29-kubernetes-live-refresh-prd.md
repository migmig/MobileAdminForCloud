# Kubernetes Live Refresh PRD

## Summary

Extend the macOS Kubernetes detail pane with manual refresh controls and a single auto-refresh toggle for rollout status, events, and logs so operators can follow changing state without repeatedly reloading the whole screen.

## Problem

The current Kubernetes feature can browse resources, perform actions, inspect rollout status, events, describe output, and YAML, but operators still need to manually re-trigger refreshes to follow changing runtime state. This is especially awkward for deployment rollout status, pod events, and pod logs, which are the most time-sensitive operational views.

## Goal

Add read-only live refresh behavior for rollout status, events, and logs inside the existing macOS Kubernetes detail pane.

## Target User

- A macOS operator already using the app's kubectl-backed Kubernetes screen
- A user watching rollout progress or troubleshooting a pod without wanting to switch to Terminal

## In Scope

- macOS-only enhancement to the existing Kubernetes detail pane
- Manual refresh controls for rollout status, events, and logs
- A single auto-refresh toggle that periodically refreshes supported operational sections for the currently selected resource
- Deployment selection: rollout status + events auto-refresh
- Pod selection: events + logs auto-refresh
- Resetting/cancelling active refresh behavior when resource, namespace, or context changes
- Clear loading/error state handling for repeated refreshes

## Out of Scope

- New sidebar routes or separate screens
- Namespace-wide watch/polling
- True streaming `kubectl logs -f`
- Full Kubernetes watch API support
- Auto-refresh for describe/YAML in this slice

## User Stories

1. As a macOS operator, I can manually refresh rollout status, events, or logs without reloading the entire screen.
2. As a macOS operator, I can enable auto-refresh while watching a deployment rollout.
3. As a macOS operator, I can enable auto-refresh while watching pod events and logs.
4. As a macOS operator, changing the selected resource, namespace, or context stops stale refresh activity and prevents outdated content from lingering.

## Success Criteria

- Rollout status, events, and logs each expose a manual refresh entry point.
- A single auto-refresh toggle updates only the operational data relevant to the currently selected resource.
- Switching selection, namespace, or context cancels or resets any stale auto-refresh cycle.
- Unsupported resource types do not expose misleading live-refresh behavior.

## Constraints

- Follow the current architecture: `ViewModel` facade plus `KubernetesService`.
- Keep the existing single Kubernetes route and detail pane structure.
- Use Apple frameworks already in the repo.
- Keep polling bounded and predictable for a desktop UI.

## Risks

- Duplicate polling tasks can create inconsistent UI updates if not cancelled cleanly.
- Auto-refresh can continue using stale selection/context if resets are incomplete.
- Frequent kubectl calls can create noisy UX or unnecessary load if the refresh interval is too aggressive.

## Acceptance Criteria

- Manual refresh works for rollout status, events, and logs in the existing detail pane.
- Deployment auto-refresh updates rollout status and events only.
- Pod auto-refresh updates events and logs only.
- Service, ConfigMap, and Secret selections do not run unsupported auto-refresh behavior.
- Resource, namespace, and context changes clear or cancel stale live-refresh state.
