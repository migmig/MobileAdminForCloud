# macOS kubectl Kubernetes Integration PRD

## Summary

Enable the macOS version of MobileAdminForCloud to use the host machine's installed `kubectl` so an operator can inspect Kubernetes resources and perform a small set of operational actions without leaving the app.

## Problem

The current app already has DevTools features for builds, pipelines, deploys, and commits, but it cannot operate against Kubernetes clusters available on the same Mac. Operators currently need to switch out to Terminal for common cluster inspection and simple operational tasks.

## Goal

Add a macOS-only Kubernetes feature that wraps local `kubectl` for a safe, constrained first release.

## Target User

- A macOS user running this app on a machine where `kubectl` is already installed
- The same user already has valid kubeconfig/context access outside the app
- The user wants quick operational visibility and a few high-frequency actions

## In Scope

- macOS-only Kubernetes UI entry point inside the existing DevTools area
- Detect whether `kubectl` is available on the host
- Read current context and available contexts
- Read namespaces
- Read pods in the selected namespace
- Read deployments in the selected namespace
- Read services in the selected namespace
- Read config maps in the selected namespace
- Read secrets in the selected namespace using a safe default view
- Allow explicit per-key secret reveal only through deliberate user action
- Allow searching/filtering across the Kubernetes resource lists shown in the macOS screen
- Read pod logs
- Run these controlled actions:
  - deployment scale
  - deployment rollout restart
  - pod delete
- Show actionable errors when `kubectl`, kubeconfig, context, or command execution fails

## Out of Scope

- iOS Kubernetes support
- Arbitrary user-entered `kubectl` commands
- Helm support
- `kubectl exec`, port-forward, apply, edit, or manifest authoring
- Cluster auth/bootstrap flows beyond using the host's existing kubeconfig
- Background streaming/watch mode in the first release

## User Stories

1. As a macOS operator, I can see whether the app can use local `kubectl`.
2. As a macOS operator, I can choose a context and namespace and inspect pods and deployments.
3. As a macOS operator, I can inspect services, config maps, and secrets for the selected namespace.
4. As a macOS operator, I can open logs for a pod without switching to Terminal.
5. As a macOS operator, I can scale a deployment, restart a rollout, or delete a pod from the app.
6. As a macOS operator, I receive clear feedback when the command fails or Kubernetes access is unavailable.

## Success Criteria

- The macOS app exposes a clear Kubernetes screen inside DevTools.
- The app can successfully run constrained `kubectl` commands through the host environment.
- Inspection flows work without requiring manual Terminal use for the supported operations.
- Secrets are displayed with safe defaults and do not expose raw values automatically.
- Users can quickly narrow services, config maps, and secrets through in-screen search/filtering.
- Dangerous or unsupported commands are not exposed.
- Failure cases are understandable to the user.

## Constraints

- Follow the existing repository architecture: `ViewModel` facade plus service-layer logic.
- Use Apple frameworks already present in the repo; do not add external dependencies.
- Keep the first release narrow and operationally safe.
- Preserve platform separation: macOS-only behavior must not leak into iOS code paths.

## Risks

- `kubectl` may not be installed or may not be on PATH in the app process.
- The app process may see a different shell environment than Terminal.
- `kubectl` output can fail or change shape if JSON decoding assumptions are too strict.
- Operational actions need confirmation and clear status reporting to avoid unsafe UX.
- Secret display can leak sensitive data if the UI shows decoded values by default.
- Search/filter behavior can become misleading if resource matching is inconsistent across types.

## Acceptance Criteria

- A macOS user with a working local `kubectl` setup can browse contexts, namespaces, pods, deployments, services, config maps, secrets, and logs.
- A macOS user can scale a deployment, trigger rollout restart, and delete a pod.
- The app blocks unsupported freeform command execution.
- Secret views show metadata and key names/count by default, not raw values.
- Secret values are only revealed when the user explicitly requests them per key.
- The Kubernetes resource lists support search/filtering for faster navigation.
- Missing binary, missing kubeconfig, bad context, and non-zero exit codes are surfaced cleanly.
- The design remains extensible for future Kubernetes resources without requiring an architectural rewrite.
