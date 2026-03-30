# Kubernetes ConfigMap and Secret YAML Design

**Date:** 2026-03-29  
**Status:** Approved for planning  
**Platform:** macOS only

## Goal

Add ConfigMap YAML and Secret YAML viewing to the existing Kubernetes inspector, with explicit key-level Secret reveal/copy support.

## Chosen Approach

Extend the existing `YAML` inspector mode instead of creating a new route or new inspector mode.

Behavior by resource type:

- Pod: existing YAML behavior remains
- Deployment: existing YAML behavior remains
- Service: existing YAML behavior remains
- ConfigMap: add YAML support
- Secret: add raw YAML support plus Secret-specific reveal panel

## Why This Approach

The current branch already has a working YAML inspector flow. ConfigMap and Secret YAML are the next natural extension. Reusing the existing YAML mode keeps the UX consistent and minimizes route/state churn, while a Secret-specific helper panel keeps the sensitive part of the feature explicit and bounded.

## Functional Scope

### YAML support added in this slice

- ConfigMap YAML
- Secret YAML

### Secret-specific support

- key list derived from the selected `KubernetesSecretInfo`
- explicit per-key reveal
- explicit per-key copy of decoded value
- raw YAML warning text

### Explicit exclusions

- no YAML editing or apply
- no automatic redaction of raw YAML in this slice
- no ConfigMap/Secret describe in this slice

## Architecture

### 1. Service layer

No new dedicated service API is required if `fetchResourceYAML(kind:name:namespace:)` already exists. Reuse it for:

- `kind = "configmap"`
- `kind = "secret"`

### 2. ViewModel additions

Extend the current document-loading logic with:

- `loadSelectedConfigMapDocuments()`
- `loadSelectedSecretDocuments()`

Rules:

- ConfigMap selection loads YAML only and clears describe
- Secret selection loads YAML only and clears describe
- Secret selection keeps key metadata from `selectedKubeSecret` for reveal/copy actions
- Resource, namespace, and context changes must clear stale YAML and stale reveal state

### 3. YAML inspector behavior

In `KubernetesDetailViewForMac`:

- ConfigMap selection
  - YAML mode available
  - raw YAML shown in the existing raw-text viewer

- Secret selection
  - YAML mode available
  - raw YAML shown in the existing raw-text viewer
  - warning text clearly explains that Secret YAML contains encoded values
  - additional key-level panel shows:
    - key name
    - reveal/hide control
    - copy decoded value control

### 4. Safety boundaries

The user explicitly chose raw Secret YAML display, so the raw YAML is not redacted in this slice. Because of that, the UI must make the risk legible:

- warning text visible in the Secret YAML view
- decoded values still require explicit reveal per key
- copy still requires explicit reveal first

### 5. State reset rules

The following must clear Secret reveal state and stale YAML:

- selected resource change
- namespace change
- context change
- leaving YAML mode is optional, but leaving the selected Secret must reset reveal state

## Data Flow

1. User selects a ConfigMap or Secret in the Kubernetes list.
2. Existing selection state updates in `ViewModel`.
3. `ViewModel` clears stale describe/YAML state.
4. `ViewModel` loads YAML via `fetchResourceYAML(...)`.
5. `KubernetesDetailViewForMac` renders the YAML mode.
6. For Secret selections, the key-level reveal/copy helper panel is rendered using the selected Secret metadata.

## Error Handling

Minimum cases:

- YAML fetch failure for ConfigMap or Secret
- Secret key decode failure
- stale revealed values surviving a selection/scope change

Rules:

- use the existing Kubernetes error state for fetch failures
- decoding failures should stay local to the key display and not break the entire YAML panel
- stale revealed values must be cleared aggressively

## Testing Strategy

### Unit tests

- `KubernetesServiceTests`
  - ConfigMap YAML command arguments
  - Secret YAML command arguments
- `ViewModelKubernetesTests`
  - ConfigMap selection loads YAML and clears describe
  - Secret selection loads YAML and clears describe
  - namespace/context/resource changes clear stale document state
- `KubernetesResourceInfoTests`
  - Secret decoded reveal/copy behavior remains explicit and key-scoped

### Manual verification

On a macOS machine with working kubectl:

1. Select a ConfigMap and verify YAML mode shows content.
2. Select a Secret and verify YAML mode shows raw YAML plus warning text.
3. Reveal one Secret key and verify only that key’s decoded value appears.
4. Copy the revealed Secret value and verify copy is blocked until reveal.
5. Switch resource or namespace/context and verify stale YAML/reveal state clears.

## Incremental Delivery

1. Extend `ViewModel` document loaders to support ConfigMap and Secret YAML.
2. Extend the YAML inspector mode UI for ConfigMap and Secret cases.
3. Add Secret warning and key-level reveal/copy panel.
4. Add focused tests for the new branches and reset behavior.

## Non-Goals for This Spec

This spec does not add YAML editing, YAML apply, automatic redaction of the raw Secret YAML view, or ConfigMap/Secret describe support.
