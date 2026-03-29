# macOS kubectl Kubernetes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a macOS-only Kubernetes DevTools feature that uses the host machine's installed `kubectl` to inspect contexts, namespaces, pods, deployments, and logs, and to run scale / rollout restart / pod delete actions.

**Architecture:** Keep the existing `ViewModel -> Service` structure and isolate local process execution behind a `KubectlRunner`. Decode supported `kubectl -o json` responses into focused `Codable` models, expose macOS-only UI in the DevTools navigation, and use typed errors plus explicit confirmation for mutating actions.

**Tech Stack:** Swift, SwiftUI, Foundation, Logging, Apple's Testing framework, xcodebuild

---

## File Structure

- Create: `MobileAdmin/model/services/KubernetesCommandError.swift` — typed kubectl/process errors surfaced to the UI.
- Create: `MobileAdmin/model/services/KubectlRunner.swift` — constrained local `kubectl` execution layer.
- Create: `MobileAdmin/model/services/KubernetesService.swift` — fixed-function Kubernetes operations.
- Create: `MobileAdmin/model/DevTools/KubernetesContextInfo.swift` — context and namespace models.
- Create: `MobileAdmin/model/DevTools/KubernetesPodInfo.swift` — pod list and log-related models.
- Create: `MobileAdmin/model/DevTools/KubernetesDeploymentInfo.swift` — deployment list models.
- Create: `MobileAdmin/views/macos/KubernetesListViewForMac.swift` — macOS list pane for namespaces, pods, deployments.
- Create: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift` — macOS detail pane for logs and actions.
- Create: `MobileAdminTests/KubectlRunnerTests.swift` — runner success/error tests.
- Create: `MobileAdminTests/KubernetesServiceTests.swift` — decoding and command-construction tests.
- Create: `MobileAdminTests/ViewModelKubernetesTests.swift` — observable state and forwarding tests.
- Modify: `MobileAdmin/model/ViewModel.swift` — inject Kubernetes service and state.
- Modify: `MobileAdmin/model/NavigationState.swift` — selected Kubernetes items.
- Modify: `MobileAdmin/views/macos/SlidebarViewForMac.swift` — add Kubernetes sidebar item.
- Modify: `MobileAdmin/views/macos/ContentListViewForMac.swift` — route sidebar selection to Kubernetes list view.
- Modify: `MobileAdmin/views/macos/DetailViewForMac.swift` — route selection to Kubernetes detail view.

### Task 1: Kubectl runner foundation

**Files:**
- Create: `MobileAdmin/model/services/KubernetesCommandError.swift`
- Create: `MobileAdmin/model/services/KubectlRunner.swift`
- Test: `MobileAdminTests/KubectlRunnerTests.swift`

- [ ] **Step 1: Write the failing tests for runner result mapping and missing kubectl handling**

```swift
import Testing
import Foundation
@testable import MobileAdmin

struct KubectlRunnerTests {
    @Test func run_whenCommandSucceeds_returnsTrimmedStdout() async throws {
        let runner = KubectlRunner(
            processRunner: { executable, arguments in
                #expect(executable == "/usr/local/bin/kubectl")
                #expect(arguments == ["config", "current-context"])
                return KubectlCommandResult(stdout: "dev-context\n", stderr: "", exitCode: 0)
            },
            executableCandidates: ["/usr/local/bin/kubectl"]
        )

        let value = try await runner.run(arguments: ["config", "current-context"])

        #expect(value.stdout == "dev-context")
        #expect(value.exitCode == 0)
    }

    @Test func run_whenNoExecutableCandidate_throwsKubectlNotInstalled() async {
        let runner = KubectlRunner(
            processRunner: { _, _ in Issue.record("process runner should not be called"); return .init(stdout: "", stderr: "", exitCode: 0) },
            executableCandidates: []
        )

        await #expect(throws: KubernetesCommandError.self) {
            _ = try await runner.run(arguments: ["version", "--client"])
        }
    }

    @Test func run_whenExitCodeNonZero_throwsCommandFailed() async {
        let runner = KubectlRunner(
            processRunner: { _, arguments in
                #expect(arguments == ["get", "pods", "-n", "prod", "-o", "json"])
                return KubectlCommandResult(stdout: "", stderr: "pods is forbidden", exitCode: 1)
            },
            executableCandidates: ["/usr/local/bin/kubectl"]
        )

        do {
            _ = try await runner.run(arguments: ["get", "pods", "-n", "prod", "-o", "json"])
            Issue.record("Expected command failure")
        } catch let error as KubernetesCommandError {
            if case .commandFailed(let stderr, let exitCode, let command) = error {
                #expect(stderr == "pods is forbidden")
                #expect(exitCode == 1)
                #expect(command.contains("kubectl get pods -n prod -o json"))
            } else {
                Issue.record("Expected .commandFailed but got \(error)")
            }
        } catch {
            Issue.record("Expected KubernetesCommandError but got \(error)")
        }
    }

    @Test func run_whenFirstExecutableMissing_triesNextCandidate() async throws {
        let runner = KubectlRunner(
            processRunner: { executable, _ in
                if executable == "/opt/homebrew/bin/kubectl" {
                    throw KubernetesCommandError.kubectlNotInstalled
                }
                return KubectlCommandResult(stdout: "prod-context", stderr: "", exitCode: 0)
            },
            executableCandidates: ["/opt/homebrew/bin/kubectl", "/usr/local/bin/kubectl"]
        )

        let result = try await runner.run(arguments: ["config", "current-context"])

        #expect(result.stdout == "prod-context")
    }
}
```

- [ ] **Step 2: Run the runner test suite and verify it fails for the expected reason**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubectlRunnerTests'
```

Expected: FAIL because `KubectlRunner`, `KubectlCommandResult`, and `KubernetesCommandError` do not exist yet.

- [ ] **Step 3: Add the minimal typed errors and runner implementation**

`MobileAdmin/model/services/KubernetesCommandError.swift`

```swift
import Foundation

enum KubernetesCommandError: LocalizedError, Equatable {
    case kubectlNotInstalled
    case commandFailed(stderr: String, exitCode: Int32, command: String)
    case invalidUTF8Output
    case decodingFailed(command: String, underlying: String)

    var errorDescription: String? {
        switch self {
        case .kubectlNotInstalled:
            return "kubectl 이 설치되어 있지 않거나 앱 환경에서 찾을 수 없습니다"
        case .commandFailed(let stderr, let exitCode, let command):
            return "kubectl 실행 실패 (\(exitCode)): \(command)\n\(stderr)"
        case .invalidUTF8Output:
            return "kubectl 출력이 UTF-8 문자열이 아닙니다"
        case .decodingFailed(let command, let underlying):
            return "kubectl 응답 파싱 실패: \(command)\n\(underlying)"
        }
    }
}
```

`MobileAdmin/model/services/KubectlRunner.swift`

```swift
import Foundation

struct KubectlCommandResult: Equatable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

protocol KubectlRunning {
    func run(arguments: [String]) async throws -> KubectlCommandResult
}

struct KubectlRunner: KubectlRunning {
    typealias ProcessRunner = @Sendable (_ executable: String, _ arguments: [String]) async throws -> KubectlCommandResult

    private let processRunner: ProcessRunner
    private let executableCandidates: [String]

    init(
        processRunner: @escaping ProcessRunner = KubectlRunner.runProcess,
        executableCandidates: [String] = ["/opt/homebrew/bin/kubectl", "/usr/local/bin/kubectl", "/usr/bin/kubectl"]
    ) {
        self.processRunner = processRunner
        self.executableCandidates = executableCandidates
    }

    func run(arguments: [String]) async throws -> KubectlCommandResult {
        guard !executableCandidates.isEmpty else {
            throw KubernetesCommandError.kubectlNotInstalled
        }

        var lastInstallError: KubernetesCommandError?
        for executable in executableCandidates {
            do {
                let result = try await processRunner(executable, arguments)
                if result.exitCode != 0 {
                    let command = (["kubectl"] + arguments).joined(separator: " ")
                    throw KubernetesCommandError.commandFailed(stderr: result.stderr, exitCode: result.exitCode, command: command)
                }

                return KubectlCommandResult(
                    stdout: result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                    stderr: result.stderr.trimmingCharacters(in: .whitespacesAndNewlines),
                    exitCode: result.exitCode
                )
            } catch let error as KubernetesCommandError {
                if case .kubectlNotInstalled = error {
                    lastInstallError = error
                    continue
                }
                throw error
            }
        }

        throw lastInstallError ?? .kubectlNotInstalled
    }

    private static func runProcess(executable: String, arguments: [String]) async throws -> KubectlCommandResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { process in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                guard let stdout = String(data: stdoutData, encoding: .utf8),
                      let stderr = String(data: stderrData, encoding: .utf8) else {
                    continuation.resume(throwing: KubernetesCommandError.invalidUTF8Output)
                    return
                }
                continuation.resume(returning: KubectlCommandResult(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: KubernetesCommandError.kubectlNotInstalled)
            }
        }
    }
}
```

- [ ] **Step 4: Run the runner test suite and verify it passes**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubectlRunnerTests'
```

Expected: PASS for `MobileAdminTests/KubectlRunnerTests`.

- [ ] **Step 5: Commit the runner foundation**

```bash
git add MobileAdmin/model/services/KubernetesCommandError.swift MobileAdmin/model/services/KubectlRunner.swift MobileAdminTests/KubectlRunnerTests.swift
git commit -m "Add kubectl runner foundation"
```

### Task 2: Kubernetes service and models

**Files:**
- Create: `MobileAdmin/model/services/KubernetesService.swift`
- Create: `MobileAdmin/model/DevTools/KubernetesContextInfo.swift`
- Create: `MobileAdmin/model/DevTools/KubernetesPodInfo.swift`
- Create: `MobileAdmin/model/DevTools/KubernetesDeploymentInfo.swift`
- Test: `MobileAdminTests/KubernetesServiceTests.swift`

- [ ] **Step 1: Write failing tests for decoding and command construction**

```swift
import Testing
import Foundation
@testable import MobileAdmin

final class StubKubectlRunner: KubectlRunning {
    enum Outcome {
        case success(KubectlCommandResult)
        case failure(Error)
    }

    private let outputs: [[String]: Outcome]
    private(set) var recordedArguments: [[String]] = []

    init(outputs: [[String]: Outcome] = [:]) {
        self.outputs = outputs
    }

    func run(arguments: [String]) async throws -> KubectlCommandResult {
        recordedArguments.append(arguments)
        guard let outcome = outputs[arguments] else {
            throw KubernetesCommandError.commandFailed(
                stderr: "Missing stubbed output",
                exitCode: 99,
                command: (["kubectl"] + arguments).joined(separator: " ")
            )
        }

        switch outcome {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
}

struct KubernetesServiceTests {
    @Test func fetchNamespaces_decodesMetadataNames() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["get", "namespaces", "-o", "json"]: .success(
                KubectlCommandResult(
                    stdout: #"{"items":[{"metadata":{"name":"default"}},{"metadata":{"name":"prod"}}]}"#,
                    stderr: "",
                    exitCode: 0
                )
            )
        ])
        let service = KubernetesService(runner: runner)

        let namespaces = try await service.fetchNamespaces()

        #expect(namespaces.map(\.name) == ["default", "prod"])
    }

    @Test func scaleDeployment_passesNamespaceNameAndReplicaCount() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["scale", "deployment", "api", "-n", "prod", "--replicas=3"]: .success(
                KubectlCommandResult(stdout: "scaled", stderr: "", exitCode: 0)
            )
        ])
        let service = KubernetesService(runner: runner)

        try await service.scaleDeployment(name: "api", namespace: "prod", replicas: 3)

        #expect(runner.recordedArguments == [["scale", "deployment", "api", "-n", "prod", "--replicas=3"]])
    }

    @Test func fetchPodLogs_returnsPlainText() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["logs", "api-123", "-n", "prod", "--tail=200"]: .success(
                KubectlCommandResult(stdout: "line1\nline2\n", stderr: "", exitCode: 0)
            )
        ])
        let service = KubernetesService(runner: runner)

        let logs = try await service.fetchPodLogs(name: "api-123", namespace: "prod")

        #expect(logs == "line1\nline2")
    }
}
```

- [ ] **Step 2: Run the service test suite and verify it fails because the service and models are missing**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesServiceTests'
```

Expected: FAIL because `KubernetesService` and the Kubernetes models do not exist yet.

- [ ] **Step 3: Add focused models and the fixed-function Kubernetes service**

`MobileAdmin/model/DevTools/KubernetesContextInfo.swift`

```swift
import Foundation

struct KubernetesContextInfo: Equatable, Identifiable {
    let id: String
    let name: String

    init(name: String) {
        self.id = name
        self.name = name
    }
}

struct KubernetesNamespaceInfo: Codable, Equatable, Identifiable {
    let name: String
    var id: String { name }
}

struct KubernetesNamespaceListResponse: Codable {
    let items: [KubernetesNamespaceItem]
}

struct KubernetesNamespaceItem: Codable {
    let metadata: KubernetesNamespaceMetadata
}

struct KubernetesNamespaceMetadata: Codable {
    let name: String
}
```

`MobileAdmin/model/DevTools/KubernetesPodInfo.swift`

```swift
import Foundation

struct KubernetesPodInfo: Codable, Equatable, Identifiable {
    let name: String
    let phase: String
    let containerCount: Int
    let readyCount: Int
    var id: String { name }
}

struct KubernetesPodListResponse: Codable {
    let items: [KubernetesPodItem]
}

struct KubernetesPodItem: Codable {
    let metadata: KubernetesNamespaceMetadata
    let spec: KubernetesPodSpec
    let status: KubernetesPodStatus
}

struct KubernetesPodSpec: Codable { let containers: [KubernetesNamedContainer] }
struct KubernetesNamedContainer: Codable { let name: String }
struct KubernetesPodStatus: Codable {
    let phase: String
    let containerStatuses: [KubernetesContainerStatus]?
}
struct KubernetesContainerStatus: Codable { let ready: Bool }
```

`MobileAdmin/model/DevTools/KubernetesDeploymentInfo.swift`

```swift
import Foundation

struct KubernetesDeploymentInfo: Codable, Equatable, Identifiable {
    let name: String
    let replicas: Int
    let readyReplicas: Int
    let availableReplicas: Int
    var id: String { name }
}

struct KubernetesDeploymentListResponse: Codable {
    let items: [KubernetesDeploymentItem]
}

struct KubernetesDeploymentItem: Codable {
    let metadata: KubernetesNamespaceMetadata
    let spec: KubernetesDeploymentSpec
    let status: KubernetesDeploymentStatus
}

struct KubernetesDeploymentSpec: Codable { let replicas: Int? }
struct KubernetesDeploymentStatus: Codable {
    let readyReplicas: Int?
    let availableReplicas: Int?
}
```

`MobileAdmin/model/services/KubernetesService.swift`

```swift
import Foundation

protocol KubernetesServicing {
    func checkAvailability() async throws
    func fetchCurrentContext() async throws -> String
    func fetchContexts() async throws -> [KubernetesContextInfo]
    func useContext(_ name: String) async throws
    func fetchNamespaces() async throws -> [KubernetesNamespaceInfo]
    func fetchPods(namespace: String) async throws -> [KubernetesPodInfo]
    func fetchDeployments(namespace: String) async throws -> [KubernetesDeploymentInfo]
    func fetchPodLogs(name: String, namespace: String) async throws -> String
    func scaleDeployment(name: String, namespace: String, replicas: Int) async throws
    func rolloutRestartDeployment(name: String, namespace: String) async throws
    func deletePod(name: String, namespace: String) async throws
}

struct KubernetesService: KubernetesServicing {
    let runner: KubectlRunning

    init(runner: KubectlRunning = KubectlRunner()) {
        self.runner = runner
    }

    func checkAvailability() async throws {
        _ = try await runner.run(arguments: ["version", "--client"])
    }

    func fetchCurrentContext() async throws -> String {
        let result = try await runner.run(arguments: ["config", "current-context"])
        return result.stdout
    }

    func fetchContexts() async throws -> [KubernetesContextInfo] {
        let result = try await runner.run(arguments: ["config", "get-contexts", "-o", "name"])
        return result.stdout
            .split(separator: "\n")
            .map { KubernetesContextInfo(name: String($0)) }
    }

    func useContext(_ name: String) async throws {
        _ = try await runner.run(arguments: ["config", "use-context", name])
    }

    func fetchNamespaces() async throws -> [KubernetesNamespaceInfo] {
        let command = ["get", "namespaces", "-o", "json"]
        let result = try await runner.run(arguments: command)
        let decoded = try decode(KubernetesNamespaceListResponse.self, from: result.stdout, command: command)
        return decoded.items.map { KubernetesNamespaceInfo(name: $0.metadata.name) }
    }

    func fetchPods(namespace: String) async throws -> [KubernetesPodInfo] {
        let command = ["get", "pods", "-n", namespace, "-o", "json"]
        let result = try await runner.run(arguments: command)
        let decoded = try decode(KubernetesPodListResponse.self, from: result.stdout, command: command)
        return decoded.items.map {
            KubernetesPodInfo(
                name: $0.metadata.name,
                phase: $0.status.phase,
                containerCount: $0.spec.containers.count,
                readyCount: $0.status.containerStatuses?.filter(\.ready).count ?? 0
            )
        }
    }

    func fetchDeployments(namespace: String) async throws -> [KubernetesDeploymentInfo] {
        let command = ["get", "deployments", "-n", namespace, "-o", "json"]
        let result = try await runner.run(arguments: command)
        let decoded = try decode(KubernetesDeploymentListResponse.self, from: result.stdout, command: command)
        return decoded.items.map {
            KubernetesDeploymentInfo(
                name: $0.metadata.name,
                replicas: $0.spec.replicas ?? 0,
                readyReplicas: $0.status.readyReplicas ?? 0,
                availableReplicas: $0.status.availableReplicas ?? 0
            )
        }
    }

    func fetchPodLogs(name: String, namespace: String) async throws -> String {
        let result = try await runner.run(arguments: ["logs", name, "-n", namespace, "--tail=200"])
        return result.stdout
    }

    func scaleDeployment(name: String, namespace: String, replicas: Int) async throws {
        _ = try await runner.run(arguments: ["scale", "deployment", name, "-n", namespace, "--replicas=\(replicas)"])
    }

    func rolloutRestartDeployment(name: String, namespace: String) async throws {
        _ = try await runner.run(arguments: ["rollout", "restart", "deployment", name, "-n", namespace])
    }

    func deletePod(name: String, namespace: String) async throws {
        _ = try await runner.run(arguments: ["delete", "pod", name, "-n", namespace])
    }

    private func decode<T: Decodable>(_ type: T.Type, from output: String, command: [String]) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: Data(output.utf8))
        } catch {
            throw KubernetesCommandError.decodingFailed(
                command: (["kubectl"] + command).joined(separator: " "),
                underlying: error.localizedDescription
            )
        }
    }
}
```

- [ ] **Step 4: Run the service tests and verify they pass**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesServiceTests'
```

Expected: PASS for `MobileAdminTests/KubernetesServiceTests`.

- [ ] **Step 5: Commit the service and models**

```bash
git add MobileAdmin/model/services/KubernetesService.swift MobileAdmin/model/DevTools/KubernetesContextInfo.swift MobileAdmin/model/DevTools/KubernetesPodInfo.swift MobileAdmin/model/DevTools/KubernetesDeploymentInfo.swift MobileAdminTests/KubernetesServiceTests.swift
git commit -m "Add Kubernetes service and models"
```

### Task 3: ViewModel and macOS navigation wiring

**Files:**
- Modify: `MobileAdmin/model/ViewModel.swift`
- Modify: `MobileAdmin/model/NavigationState.swift`
- Modify: `MobileAdmin/views/macos/SlidebarViewForMac.swift`
- Modify: `MobileAdmin/views/macos/ContentListViewForMac.swift`
- Modify: `MobileAdmin/views/macos/DetailViewForMac.swift`
- Test: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Write the failing view model tests for state updates and forwarding**

```swift
import Testing
import Foundation
@testable import MobileAdmin

final class StubKubernetesService: KubernetesServicing {
    var currentContext: String
    var contexts: [KubernetesContextInfo]
    var namespaces: [KubernetesNamespaceInfo]
    var pods: [KubernetesPodInfo]
    var deployments: [KubernetesDeploymentInfo]
    var logs: String
    var deletedPods: [(namespace: String, name: String)] = []
    var scaledDeployments: [(namespace: String, name: String, replicas: Int)] = []
    var restartedDeployments: [(namespace: String, name: String)] = []
    var switchedContexts: [String] = []

    init(
        currentContext: String = "",
        contexts: [KubernetesContextInfo] = [],
        namespaces: [KubernetesNamespaceInfo] = [],
        pods: [KubernetesPodInfo] = [],
        deployments: [KubernetesDeploymentInfo] = [],
        logs: String = ""
    ) {
        self.currentContext = currentContext
        self.contexts = contexts
        self.namespaces = namespaces
        self.pods = pods
        self.deployments = deployments
        self.logs = logs
    }

    func checkAvailability() async throws {}
    func fetchCurrentContext() async throws -> String { currentContext }
    func fetchContexts() async throws -> [KubernetesContextInfo] { contexts }
    func useContext(_ name: String) async throws { switchedContexts.append(name); currentContext = name }
    func fetchNamespaces() async throws -> [KubernetesNamespaceInfo] { namespaces }
    func fetchPods(namespace: String) async throws -> [KubernetesPodInfo] { pods }
    func fetchDeployments(namespace: String) async throws -> [KubernetesDeploymentInfo] { deployments }
    func fetchPodLogs(name: String, namespace: String) async throws -> String { logs }
    func scaleDeployment(name: String, namespace: String, replicas: Int) async throws { scaledDeployments.append((namespace, name, replicas)) }
    func rolloutRestartDeployment(name: String, namespace: String) async throws { restartedDeployments.append((namespace, name)) }
    func deletePod(name: String, namespace: String) async throws { deletedPods.append((namespace, name)) }
}

struct ViewModelKubernetesTests {
    @Test func refreshKubernetesOverview_updatesContextNamespacePodsAndDeployments() async throws {
        let service = StubKubernetesService(
            currentContext: "prod-cluster",
            contexts: [KubernetesContextInfo(name: "prod-cluster")],
            namespaces: [KubernetesNamespaceInfo(name: "prod")],
            pods: [KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)],
            deployments: [KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)]
        )
        let viewModel = ViewModel(kubernetesService: service)

        await viewModel.refreshKubernetesOverview()

        #expect(viewModel.selectedKubeContext == "prod-cluster")
        #expect(viewModel.selectedKubeNamespace == "prod")
        #expect(viewModel.kubePods.map(\.name) == ["api-123"])
        #expect(viewModel.kubeDeployments.map(\.name) == ["api"])
    }

    @Test func deleteSelectedPod_forwardsNamespaceAndPodName() async throws {
        let service = StubKubernetesService()
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)

        try await viewModel.deleteSelectedPod()

        #expect(service.deletedPods == [(namespace: "prod", name: "api-123")])
    }

    @Test func switchKubernetesContext_forwardsSelectionAndRefreshesCurrentContext() async {
        let service = StubKubernetesService(
            currentContext: "dev-cluster",
            contexts: [KubernetesContextInfo(name: "dev-cluster"), KubernetesContextInfo(name: "prod-cluster")],
            namespaces: [KubernetesNamespaceInfo(name: "prod")]
        )
        let viewModel = ViewModel(kubernetesService: service)

        await viewModel.switchKubernetesContext(to: "prod-cluster")

        #expect(service.switchedContexts == ["prod-cluster"])
        #expect(viewModel.selectedKubeContext == "prod-cluster")
    }
}
```

- [ ] **Step 2: Run the view model suite and verify it fails because the new state and methods do not exist**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
```

Expected: FAIL because `ViewModel` does not yet expose Kubernetes state or forwarding methods.

- [ ] **Step 3: Add Kubernetes observable state and macOS navigation hooks**

`MobileAdmin/model/ViewModel.swift` additions

```swift
    @Published var kubeContexts: [KubernetesContextInfo] = []
    @Published var selectedKubeContext: String = ""
    @Published var kubeNamespaces: [KubernetesNamespaceInfo] = []
    @Published var selectedKubeNamespace: String = ""
    @Published var kubePods: [KubernetesPodInfo] = []
    @Published var selectedKubePod: KubernetesPodInfo?
    @Published var kubeDeployments: [KubernetesDeploymentInfo] = []
    @Published var selectedKubeDeployment: KubernetesDeploymentInfo?
    @Published var selectedPodLogs: String = ""
    @Published var kubernetesError: String?
    @Published var isKubernetesLoading = false
    @Published var isKubectlAvailable = false

    private let kubernetesService: any KubernetesServicing
```

`ViewModel.init()` update

```swift
    init(kubernetesService: any KubernetesServicing = KubernetesService()) {
        let client = NetworkClient()
        self.networkClient = client
        self.toastService = ToastService(client: client)
        self.errorService = ErrorService(client: client)
        self.goodsService = GoodsService(client: client)
        self.educationService = EducationService(client: client)
        self.codeService = CodeService(client: client)
        self.closeDeptService = CloseDeptService(client: client)
        self.buildService = BuildService(client: client)
        self.pipelineService = PipelineService(client: client)
        self.commitService = CommitService(client: client)
        self.deployService = DeployService(client: client)
        self.userLogService = UserLogService(client: client)
        self.kubernetesService = kubernetesService
    }
```

`ViewModel` methods

```swift
    @MainActor
    func refreshKubernetesOverview() async {
        isKubernetesLoading = true
        defer { isKubernetesLoading = false }

        do {
            try await kubernetesService.checkAvailability()
            isKubectlAvailable = true
            kubeContexts = try await kubernetesService.fetchContexts()
            selectedKubeContext = try await kubernetesService.fetchCurrentContext()
            kubeNamespaces = try await kubernetesService.fetchNamespaces()

            if selectedKubeNamespace.isEmpty {
                selectedKubeNamespace = kubeNamespaces.first?.name ?? ""
            }

            if !selectedKubeNamespace.isEmpty {
                kubePods = try await kubernetesService.fetchPods(namespace: selectedKubeNamespace)
                kubeDeployments = try await kubernetesService.fetchDeployments(namespace: selectedKubeNamespace)
            }

            kubernetesError = nil
        } catch {
            isKubectlAvailable = false
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func switchKubernetesContext(to name: String) async {
        do {
            try await kubernetesService.useContext(name)
            selectedKubeContext = name
            selectedKubeNamespace = ""
            await refreshKubernetesOverview()
        } catch {
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func refreshPodLogs() async {
        guard let selectedKubePod else { return }
        do {
            selectedPodLogs = try await kubernetesService.fetchPodLogs(name: selectedKubePod.name, namespace: selectedKubeNamespace)
        } catch {
            kubernetesError = error.localizedDescription
        }
    }

    func scaleSelectedDeployment(to replicas: Int) async throws {
        guard let selectedKubeDeployment else { return }
        try await kubernetesService.scaleDeployment(name: selectedKubeDeployment.name, namespace: selectedKubeNamespace, replicas: replicas)
    }

    func restartSelectedDeployment() async throws {
        guard let selectedKubeDeployment else { return }
        try await kubernetesService.rolloutRestartDeployment(name: selectedKubeDeployment.name, namespace: selectedKubeNamespace)
    }

    func deleteSelectedPod() async throws {
        guard let selectedKubePod else { return }
        try await kubernetesService.deletePod(name: selectedKubePod.name, namespace: selectedKubeNamespace)
    }
```

`MobileAdmin/model/NavigationState.swift` additions

```swift
    @Published var selectedKubePod: KubernetesPodInfo?
    @Published var selectedKubeDeployment: KubernetesDeploymentInfo?
```

`MobileAdmin/views/macos/SlidebarViewForMac.swift` additions

```swift
    case sourceKubernetes
```

```swift
        case .sourceKubernetes:
            return "Kubernetes"
```

```swift
        case .sourceKubernetes:
            return "shippingbox.circle"
```

```swift
            ("개발도구", [.sourceBuild, .sourceDeploy, .sourcePipeline, .sourceKubernetes])
```

`MobileAdmin/views/macos/ContentListViewForMac.swift` route

```swift
        case .sourceKubernetes:
            KubernetesListViewForMac()
                .environmentObject(viewModel)
                .environmentObject(nav)
```

`MobileAdmin/views/macos/DetailViewForMac.swift` route

```swift
        case .sourceKubernetes:
            KubernetesDetailViewForMac()
                .environmentObject(viewModel)
                .environmentObject(nav)
```

- [ ] **Step 4: Run the view model tests and verify they pass**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
```

Expected: PASS for `MobileAdminTests/ViewModelKubernetesTests`.

- [ ] **Step 5: Commit the view model and navigation wiring**

```bash
git add MobileAdmin/model/ViewModel.swift MobileAdmin/model/NavigationState.swift MobileAdmin/views/macos/SlidebarViewForMac.swift MobileAdmin/views/macos/ContentListViewForMac.swift MobileAdmin/views/macos/DetailViewForMac.swift MobileAdminTests/ViewModelKubernetesTests.swift
git commit -m "Wire Kubernetes into macOS navigation"
```

### Task 4: macOS Kubernetes screens and action flow

**Files:**
- Create: `MobileAdmin/views/macos/KubernetesListViewForMac.swift`
- Create: `MobileAdmin/views/macos/KubernetesDetailViewForMac.swift`
- Modify: `MobileAdmin/model/ViewModel.swift`
- Test: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Write the failing test for logs refresh after pod selection and deployment action refresh**

```swift
@Test func refreshPodLogs_afterSelectingPod_updatesSelectedPodLogs() async throws {
    let service = StubKubernetesService(logs: "ready\nserving")
    let viewModel = ViewModel(kubernetesService: service)
    viewModel.selectedKubeNamespace = "prod"
    viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)

    await viewModel.refreshPodLogs()

    #expect(viewModel.selectedPodLogs == "ready\nserving")
}
```

- [ ] **Step 2: Run the focused test and verify it fails before the UI action flow is wired**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:"MobileAdminTests/ViewModelKubernetesTests/refreshPodLogs_afterSelectingPod_updatesSelectedPodLogs()"
```

Expected: FAIL until the log-refresh path and selected pod state are wired cleanly.

- [ ] **Step 3: Add the macOS list/detail screens with explicit action confirmation**

`MobileAdmin/views/macos/KubernetesListViewForMac.swift`

```swift
import SwiftUI

struct KubernetesListViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState

    var body: some View {
        List(selection: $nav.selectedKubePod) {
            Section("Context") {
                HStack {
                    Circle()
                        .fill(viewModel.isKubectlAvailable ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isKubectlAvailable ? "kubectl 사용 가능" : "kubectl 사용 불가")
                }

                Picker("Context", selection: $viewModel.selectedKubeContext) {
                    ForEach(viewModel.kubeContexts) { item in
                        Text(item.name).tag(item.name)
                    }
                }
            }

            Section("Namespace") {
                Picker("Namespace", selection: $viewModel.selectedKubeNamespace) {
                    ForEach(viewModel.kubeNamespaces) { item in
                        Text(item.name).tag(item.name)
                    }
                }
            }

            Section("Pods") {
                ForEach(viewModel.kubePods) { pod in
                    NavigationLink(value: pod) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pod.name)
                            Text("\(pod.phase) · \(pod.readyCount)/\(pod.containerCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Deployments") {
                ForEach(viewModel.kubeDeployments) { deployment in
                    Button {
                        nav.selectedKubeDeployment = deployment
                        viewModel.selectedKubeDeployment = deployment
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deployment.name)
                            Text("ready \(deployment.readyReplicas)/\(deployment.replicas)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Kubernetes")
        .task {
            await viewModel.refreshKubernetesOverview()
        }
        .onChange(of: viewModel.selectedKubeContext) { oldValue, newValue in
            guard oldValue != newValue, !newValue.isEmpty, !oldValue.isEmpty else { return }
            Task { await viewModel.switchKubernetesContext(to: newValue) }
        }
        .onChange(of: viewModel.selectedKubeNamespace) { oldValue, newValue in
            guard oldValue != newValue, !newValue.isEmpty, !oldValue.isEmpty else { return }
            Task { await viewModel.refreshKubernetesOverview() }
        }
        .onChange(of: nav.selectedKubePod) { _, newValue in
            viewModel.selectedKubePod = newValue
            Task { await viewModel.refreshPodLogs() }
        }
    }
}
```

`MobileAdmin/views/macos/KubernetesDetailViewForMac.swift`

```swift
import SwiftUI

struct KubernetesDetailViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState
    @State private var replicaCount: Int = 1
    @State private var showDeleteConfirmation = false

    var body: some View {
        List {
            Section("Context") {
                Text(viewModel.selectedKubeContext)
                if let error = viewModel.kubernetesError, !error.isEmpty {
                    Text(error).foregroundStyle(.red)
                }
            }

            if let deployment = nav.selectedKubeDeployment {
                Section("Deployment") {
                    InfoRow(title: "이름", value: deployment.name)
                    Stepper("Replica: \(replicaCount)", value: $replicaCount, in: 0...50)
                    Button("Scale") {
                        Task {
                            try? await viewModel.scaleSelectedDeployment(to: replicaCount)
                            await viewModel.refreshKubernetesOverview()
                        }
                    }
                    Button("Rollout Restart") {
                        Task {
                            try? await viewModel.restartSelectedDeployment()
                            await viewModel.refreshKubernetesOverview()
                        }
                    }
                }
            }

            if let pod = nav.selectedKubePod {
                Section("Pod") {
                    InfoRow(title: "이름", value: pod.name)
                    Button("Delete Pod", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .confirmationDialog("선택한 Pod를 삭제하시겠습니까?", isPresented: $showDeleteConfirmation) {
                        Button("삭제", role: .destructive) {
                            Task {
                                try? await viewModel.deleteSelectedPod()
                                await viewModel.refreshKubernetesOverview()
                            }
                        }
                    }
                }

                Section("Logs") {
                    ScrollView {
                        Text(viewModel.selectedPodLogs.isEmpty ? "로그가 없습니다" : viewModel.selectedPodLogs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 240)
                }
            }
        }
        .navigationTitle("Kubernetes Detail")
        .onChange(of: nav.selectedKubeDeployment) { _, newValue in
            viewModel.selectedKubeDeployment = newValue
            replicaCount = newValue?.replicas ?? 1
        }
    }
}
```

- [ ] **Step 4: Run the focused suite, then run the broader Kubernetes suites, and verify they pass**

Run:

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/ViewModelKubernetesTests'
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubectlRunnerTests'
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:'MobileAdminTests/KubernetesServiceTests'
```

Expected: PASS for all three Kubernetes-related unit test suites.

- [ ] **Step 5: Commit the macOS Kubernetes UI**

```bash
git add MobileAdmin/views/macos/KubernetesListViewForMac.swift MobileAdmin/views/macos/KubernetesDetailViewForMac.swift MobileAdmin/model/ViewModel.swift MobileAdminTests/ViewModelKubernetesTests.swift
git commit -m "Add macOS Kubernetes management screens"
```

### Task 5: Full verification and push

**Files:**
- Modify: none expected beyond fixes found during verification
- Test: `MobileAdminTests/KubectlRunnerTests.swift`
- Test: `MobileAdminTests/KubernetesServiceTests.swift`
- Test: `MobileAdminTests/ViewModelKubernetesTests.swift`

- [ ] **Step 1: Run the full unit test plan**

```bash
xcodebuild test -project MobileAdmin.xcodeproj -scheme MobileAdmin -testPlan MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS for the full `MobileAdminTests` plan.

- [ ] **Step 2: Run a build or analyze pass for the app target**

```bash
xcodebuild analyze -project MobileAdmin.xcodeproj -scheme MobileAdmin -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: exit 0 with no new analyzer issues introduced by the Kubernetes changes.

- [ ] **Step 3: Manual macOS QA on a machine with working kubectl**

Run through this checklist:

```text
1. Open the macOS app and navigate to 개발도구 > Kubernetes.
2. Confirm current context, context picker, and namespace list load, then switch context once and verify the screen refreshes.
3. Confirm pods and deployments appear for the selected namespace.
4. Select a pod and verify logs appear.
5. Scale a deployment and confirm the refresh updates replica counts.
6. Run rollout restart and confirm the command succeeds.
7. Delete a pod, confirm the dialog appears first, then verify the list refreshes.
8. Temporarily break kubectl access and verify the error is shown clearly.
```

Expected: All supported operations work and failures are understandable.

- [ ] **Step 4: Commit only the fixes required by final verification**

```bash
git status
git add <verified-files-only>
git commit -m "Polish Kubernetes integration verification fixes"
```

Expected: Skip this step if verification finds nothing to change.

- [ ] **Step 5: Push the branch after all verification passes**

```bash
git push -u origin "$(git branch --show-current)"
```

Expected: Current branch is pushed successfully after tests, analyze, and manual QA are complete.
