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

    @Test func fetchPods_invalidJSON_wrapsDecodeFailure() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["get", "pods", "-n", "prod", "-o", "json"]: .success(
                KubectlCommandResult(stdout: #"{"items":[{"metadata":{}}]}"#, stderr: "", exitCode: 0)
            )
        ])
        let service = KubernetesService(runner: runner)

        do {
            _ = try await service.fetchPods(namespace: "prod")
            Issue.record("Expected decoding failure")
        } catch let error as KubernetesCommandError {
            if case .decodingFailed(let command, _) = error {
                #expect(command == "kubectl get pods -n prod -o json")
            } else {
                Issue.record("Expected .decodingFailed but got \(error)")
            }
        } catch {
            Issue.record("Expected KubernetesCommandError but got \(error)")
        }
    }
}
