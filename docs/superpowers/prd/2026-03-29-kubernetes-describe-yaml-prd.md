# Kubernetes Describe and YAML PRD

## Summary

Extend the macOS Kubernetes workspace so an operator can inspect `describe` output for pods and deployments, and view raw YAML for pods, deployments, and services, inside the existing Kubernetes detail pane.

## Problem

The current Kubernetes feature already supports browsing, actions, rollout status, and events, but operators still need to switch to Terminal to answer deeper resource questions such as current controller state, attached conditions, annotations, selectors, and raw YAML.

## Goal

Add read-only `describe` and YAML inspection to the existing macOS Kubernetes detail experience.

## Target User

- A macOS operator already using the app's kubectl-backed Kubernetes screen
- A user who needs deeper operational inspection without leaving the app

## In Scope

- macOS-only enhancement to the existing Kubernetes feature
- `pod describe`
- `deployment describe`
- YAML view for pod, deployment, and service
- A structured detail-pane experience that supports switching between overview/ops/describe/yaml modes
- Loading and error state handling for describe/YAML retrieval
- Clearing stale describe/YAML content when selection, namespace, or context changes

## Out of Scope

- New sidebar routes or separate Kubernetes screens
- Editing or applying YAML
- ConfigMap/Secret YAML in this slice
- `service describe` in this slice
- Streaming watch behavior

## User Stories

1. As a macOS operator, when I select a pod, I can inspect `describe` output and raw YAML.
2. As a macOS operator, when I select a deployment, I can inspect `describe` output and raw YAML.
3. As a macOS operator, when I select a service, I can inspect raw YAML.
4. As a macOS operator, stale describe/YAML content does not remain on screen after I switch resources or namespace/context.

## Success Criteria

- The existing Kubernetes detail pane exposes read-only describe/YAML inspection without adding a new route.
- Pod and deployment selections can show describe output.
- Pod, deployment, and service selections can show YAML output.
- Unsupported combinations are hidden or disabled clearly rather than showing empty stale content.

## Constraints

- Follow the current architecture: `ViewModel` facade plus `KubernetesService`.
- Keep this as a narrow extension of the existing single Kubernetes route.
- Use Apple frameworks already in the repo.

## Risks

- Large raw text outputs can make the detail pane unwieldy if not structured.
- Repeated raw text sections can reintroduce SwiftUI type-check complexity if the view is not modularized.
- Unsupported resource/type combinations can create confusing empty states if not handled explicitly.

## Acceptance Criteria

- Selecting a pod loads pod describe and pod YAML.
- Selecting a deployment loads deployment describe and deployment YAML.
- Selecting a service loads service YAML and does not expose unsupported describe output.
- Resource, namespace, and context changes clear stale describe/YAML text before new content loads.
