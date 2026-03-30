# Kubernetes ConfigMap and Secret YAML PRD

## Summary

Extend the macOS Kubernetes detail inspector so operators can view ConfigMap YAML and Secret YAML, with Secret-specific key reveal support inside the YAML experience.

## Problem

The current Kubernetes inspector already supports describe/YAML for pods, deployments, and services, but ConfigMaps and Secrets still require a context switch to Terminal for raw manifest inspection. This is especially limiting for troubleshooting configuration drift and secret shape verification.

## Goal

Add ConfigMap YAML viewing and Secret YAML viewing to the existing Kubernetes YAML inspector, with explicit per-key Secret reveal support.

## Target User

- A macOS operator already using the app’s Kubernetes inspector
- A user who needs deeper configuration inspection without leaving the app

## In Scope

- macOS-only enhancement to the existing Kubernetes detail pane
- ConfigMap YAML viewing
- Secret YAML viewing
- Secret key list and explicit per-key reveal/copy support inside the YAML experience
- Warning text explaining that raw Secret YAML includes base64-encoded values
- Clearing stale YAML/reveal state on resource, namespace, or context change

## Out of Scope

- YAML editing or apply
- ConfigMap/Secret describe in this slice
- Automatic Secret redaction of the raw YAML view
- New routes or windows

## User Stories

1. As a macOS operator, when I select a ConfigMap, I can inspect its raw YAML.
2. As a macOS operator, when I select a Secret, I can inspect its raw YAML.
3. As a macOS operator, I can explicitly reveal and copy decoded Secret values key by key.
4. As a macOS operator, stale YAML or revealed Secret values do not remain visible when I switch resources or namespace/context.

## Success Criteria

- ConfigMap selections can show YAML in the existing inspector.
- Secret selections can show raw YAML plus explicit key-level reveal/copy controls.
- The UI clearly warns that raw Secret YAML contains encoded values.
- Reveal state is cleared on selection or scope changes.

## Constraints

- Follow the current architecture: `ViewModel` facade plus `KubernetesService`.
- Keep the single Kubernetes route and the current inspector structure.
- Use Apple frameworks already in the repo.

## Risks

- Raw Secret YAML can expose encoded data too broadly if the UI does not warn clearly.
- Reveal state can leak across resource changes if not reset aggressively.
- YAML mode complexity can regress SwiftUI type-check performance if the detail view grows without structure.

## Acceptance Criteria

- Selecting a ConfigMap loads and displays its YAML.
- Selecting a Secret loads and displays its YAML.
- Secret YAML view includes a clear warning and key-level reveal/copy controls.
- Namespace, context, and resource changes clear stale YAML and revealed values.
