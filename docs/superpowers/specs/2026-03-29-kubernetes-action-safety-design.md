# Kubernetes Action Safety and Audit Design

**Date:** 2026-03-29  
**Status:** Approved for planning  
**Platform:** macOS only

## Goal

Add stronger action confirmation, persistent local audit logging, and rollback guidance for the existing Kubernetes mutating actions.

## Chosen Approach

Introduce a small action safety layer in front of the existing mutating `ViewModel` calls, and persist the resulting action history locally using Apple-native storage in a format that can later be exported.

## Why This Approach

The branch already behaves like a lightweight operations console. At this point the biggest gap is not more data display, but safer execution and traceability. A local persistent audit model plus an action wrapper keeps the current UI structure intact while giving every mutating action a consistent lifecycle.

## Functional Scope

### Actions covered in this slice

- deployment scale
- deployment rollout restart
- pod delete

### Safety features

- stronger confirmation for destructive/high-risk actions
- result summaries
- rollback / next-step guidance
- persistent local audit entries

### Explicit exclusions

- no remote/shared action history
- no export UI yet
- no automated rollback execution
- no additional mutating actions in this slice

## Architecture

### 1. Action audit model

Add a persistent local action model, for example `KubernetesActionAuditEntry`, with fields such as:

- timestamp
- action type
- resource kind
- resource name
- namespace
- requested value (for scale)
- previous value when known (for scale)
- result (`success`, `failure`, `cancelled`)
- error summary
- rollback guidance text
- actor label (`local operator` or local username if available)

The model should be easy to serialize later for JSON or CSV export.

### 2. Persistence strategy

Use Apple-native local persistence already aligned with the app's architecture. The design assumes a local persistent store managed inside the app process, not a remote service.

### 3. Action safety wrapper

Do not let each UI button implement its own logging/rollback policy separately. Add a small action execution layer that:

1. builds the action summary
2. applies the right confirmation policy
3. executes the existing Kubernetes action
4. records the audit entry
5. returns rollback guidance

This can live in `ViewModel` or a small adjacent service, but the behavior must be centralized.

### 4. Confirmation policy

- **Delete Pod**
  - destructive styling
  - 2-step confirmation
  - summary must include resource and namespace

- **Scale**
  - show previous and target replica counts when known
  - stronger warning for scale-to-zero

- **Rollout Restart**
  - confirmation explains which deployment and namespace are affected

### 5. Rollback guidance rules

Rollback guidance must be truthful and action-specific.

- **Scale**
  - if previous replicas are known, guidance should explicitly say: restore by scaling back to the previous value

- **Rollout Restart**
  - no direct undo; guidance should direct the operator to rollout status/events and deployment history

- **Delete Pod**
  - no direct undo; guidance may mention controller-managed recreation only as a conditional, not a guarantee

## UI Design

### 1. Action confirmation experience

Extend the current Kubernetes detail action UI so each supported action goes through a structured confirmation state rather than ad-hoc button behavior.

### 2. Audit history surface

Expose a local audit history area inside the existing Kubernetes detail experience or nearby operations surface.

Each entry should show:

- time
- action
- target resource
- result
- rollback guidance summary

### 3. Result messaging

After action completion or cancellation, the user should see both the result and the corresponding guidance text.

## Data Flow

1. User initiates scale / rollout restart / delete pod.
2. Safety wrapper prepares a confirmation summary.
3. User confirms or cancels.
4. If confirmed, the existing action call executes.
5. Wrapper records a persistent local audit entry.
6. UI shows result plus rollback guidance.

## Error Handling

Minimum cases:

- action cancelled by user
- action failed from kubectl/service layer
- persistence failure while recording the audit entry
- previous replica value unavailable for scale rollback guidance

Rules:

- cancellation is a first-class audit result, not an invisible no-op
- failure to store audit history should not be silently ignored
- rollback guidance must degrade gracefully when previous state is unavailable

## Testing Strategy

### Unit tests

- audit entry creation for success / failure / cancellation
- scale rollback guidance when previous replicas are known
- rollout restart and delete pod guidance when no real undo exists
- confirmation policy selection for destructive or risky actions
- persistence round-trip of audit entries

### Manual verification

On a macOS machine with working kubectl:

1. Perform scale, restart, and delete actions.
2. Confirm the stronger confirmation flow appears.
3. Confirm success/failure/cancelled results are stored in the local audit history.
4. Restart the app and confirm the audit history remains.
5. Verify scale entries include previous replica rollback guidance.

## Incremental Delivery

1. Add persistent audit model and storage.
2. Add action wrapper and rollback-guidance generation.
3. Replace direct UI action execution with wrapped execution.
4. Add audit history UI.

## Non-Goals for This Spec

This spec does not add export UI, remote audit sync, or automated rollback execution. The model should support those later, but they are not part of this slice.
