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

    @Test func fetchServices_decodesTypeAddressAndPortCount() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["get", "services", "-n", "prod", "-o", "json"]: .success(
                KubectlCommandResult(
                    stdout: #"{"items":[{"metadata":{"name":"api"},"spec":{"type":"ClusterIP","clusterIP":"10.0.0.12","ports":[{"port":80},{"port":443}]},"status":{}}]}"#,
                    stderr: "",
                    exitCode: 0
                )
            )
        ])
        let service = KubernetesService(runner: runner)

        let services = try await service.fetchServices(namespace: "prod")

        #expect(services.map(\.name) == ["api"])
        #expect(services.first?.type == "ClusterIP")
        #expect(services.first?.primaryAddress == "10.0.0.12")
        #expect(services.first?.portCount == 2)
    }

    @Test func fetchConfigMaps_decodesKeyCounts() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["get", "configmaps", "-n", "prod", "-o", "json"]: .success(
                KubectlCommandResult(
                    stdout: #"{"items":[{"metadata":{"name":"app-config"},"immutable":true,"data":{"A":"1","B":"2"},"binaryData":{"blob":"AA=="}}]}"#,
                    stderr: "",
                    exitCode: 0
                )
            )
        ])
        let service = KubernetesService(runner: runner)

        let configMaps = try await service.fetchConfigMaps(namespace: "prod")

        #expect(configMaps.map(\.name) == ["app-config"])
        #expect(configMaps.first?.textKeyCount == 2)
        #expect(configMaps.first?.binaryKeyCount == 1)
        #expect(configMaps.first?.immutable == true)
        #expect(configMaps.first?.textData["A"] == "1")
    }

    @Test func fetchSecrets_decodesMetadataAndKeysWithoutValues() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["get", "secrets", "-n", "prod", "-o", "json"]: .success(
                KubectlCommandResult(
                    stdout: #"{"items":[{"metadata":{"name":"app-secret"},"type":"Opaque","immutable":false,"data":{"username":"dXNlcg==","password":"cGFzcw=="}}]}"#,
                    stderr: "",
                    exitCode: 0
                )
            )
        ])
        let service = KubernetesService(runner: runner)

        let secrets = try await service.fetchSecrets(namespace: "prod")

        #expect(secrets.map(\.name) == ["app-secret"])
        #expect(secrets.first?.type == "Opaque")
        #expect(secrets.first?.keyNames == ["password", "username"])
        #expect(secrets.first?.keyCount == 2)
    }

    @Test func fetchRolloutStatus_passesDeploymentNamespaceAndTimeout() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["rollout", "status", "deployment/api", "-n", "prod", "--timeout=10s"]: .success(
                KubectlCommandResult(stdout: "deployment \"api\" successfully rolled out\n", stderr: "", exitCode: 0)
            )
        ])
        let service = KubernetesService(runner: runner)

        let status = try await service.fetchRolloutStatus(deployment: "api", namespace: "prod")

        #expect(status == "deployment \"api\" successfully rolled out")
        #expect(runner.recordedArguments == [["rollout", "status", "deployment/api", "-n", "prod", "--timeout=10s"]])
    }

    @Test func fetchEvents_decodesAndFiltersMatchingResourceEvents() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["get", "events", "-n", "prod", "-o", "json"]: .success(
                KubectlCommandResult(
                    stdout: #"{"items":[{"type":"Normal","reason":"Started","message":"Started container","lastTimestamp":"2026-03-29T10:00:00Z","involvedObject":{"kind":"Pod","name":"api-123"}},{"type":"Warning","reason":"BackOff","message":"Back-off restarting failed container","lastTimestamp":"2026-03-29T11:00:00Z","involvedObject":{"kind":"Pod","name":"api-123"}},{"type":"Normal","reason":"Scheduled","message":"Assigned to node","lastTimestamp":"2026-03-29T09:00:00Z","involvedObject":{"kind":"Pod","name":"worker-1"}}]}"#,
                    stderr: "",
                    exitCode: 0
                )
            )
        ])
        let service = KubernetesService(runner: runner)

        let events = try await service.fetchEvents(namespace: "prod", resourceKind: "Pod", resourceName: "api-123")

        #expect(events.map(\.reason) == ["BackOff", "Started"])
        #expect(events.allSatisfy { $0.involvedKind == "Pod" && $0.involvedName == "api-123" })
    }

    @Test func fetchEvents_invalidJSON_wrapsDecodeFailure() async throws {
        let runner = StubKubectlRunner(outputs: [
            ["get", "events", "-n", "prod", "-o", "json"]: .success(
                KubectlCommandResult(stdout: #"{"items":[{"message":"missing involved object"}]}"#, stderr: "", exitCode: 0)
            )
        ])
        let service = KubernetesService(runner: runner)

        do {
            _ = try await service.fetchEvents(namespace: "prod", resourceKind: "Pod", resourceName: "api-123")
            Issue.record("Expected decoding failure")
        } catch let error as KubernetesCommandError {
            if case .decodingFailed(let command, _) = error {
                #expect(command == "kubectl get events -n prod -o json")
            } else {
                Issue.record("Expected .decodingFailed but got \(error)")
            }
        } catch {
            Issue.record("Expected KubernetesCommandError but got \(error)")
        }
    }
}
