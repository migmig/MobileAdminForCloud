# Kubernetes Action Safety and Audit PRD

## Summary

Extend the macOS Kubernetes workspace with safer action execution, persistent local audit logging, and rollback guidance for supported actions.

## Problem

The current Kubernetes feature already supports mutating actions such as deployment scale, rollout restart, and pod delete, but the user experience is still operator-trusting rather than operator-protecting. There is no persistent action history, limited execution confirmation, and inconsistent guidance about how to undo or mitigate an action afterward.

## Goal

Add a safety layer around Kubernetes actions so operators get clear confirmation, durable local action history, and rollback guidance after execution.

## Target User

- A macOS operator performing live Kubernetes actions from the app
- A user who needs to understand what was executed and how to recover from it later

## In Scope

- macOS-only enhancement to the existing Kubernetes detail pane
- Stronger confirmation flow for destructive or risky actions
- Persistent local audit log for supported Kubernetes actions
- A storage model that is ready for later export support
- Rollback guidance for supported actions:
  - scale: previous replicas and restore guidance
  - rollout restart: no direct undo, with explicit guidance
  - delete pod: no direct undo, with cautious controller-recreation guidance only

## Out of Scope

- Remote/shared audit logging
- Server-side identity attribution
- Automatic rollback execution
- Export UI in this slice
- New Kubernetes actions beyond the existing scale / rollout restart / delete pod

## User Stories

1. As a macOS operator, before I execute a risky action, I see a strong confirmation that explains what will happen.
2. As a macOS operator, after I execute or cancel an action, I can see that result in a persistent local action history.
3. As a macOS operator, when an action completes, I can see guidance about how to recover or what to do next.
4. As a macOS operator, I can restart the app and still inspect prior action history.

## Success Criteria

- Risky actions require clearer confirmation than the current baseline.
- Every supported action produces an audit entry with success, failure, or cancellation result.
- Audit entries persist across app restarts.
- Scale actions include previous replica information suitable for later export or rollback guidance.

## Constraints

- Follow the current architecture: `ViewModel` facade plus service-layer logic.
- Use Apple frameworks already in the repo.
- Keep audit logging local-only in this slice.
- Keep the data model export-friendly even if export UI is deferred.

## Risks

- Logging too little makes the audit trail unhelpful.
- Logging too much can accidentally store sensitive or noisy payloads.
- Rollback language can over-promise if an action is not truly reversible.

## Acceptance Criteria

- Scale, rollout restart, and delete pod all create persistent local audit entries.
- Delete pod and high-risk scale paths use a stronger confirmation flow.
- Each action result includes user-facing rollback or next-step guidance.
- Restarting the app preserves previously recorded audit entries.
