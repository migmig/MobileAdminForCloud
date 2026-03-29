import Foundation

protocol KubernetesServicing {
    func checkAvailability() async throws
    func fetchCurrentContext() async throws -> String
    func fetchContexts() async throws -> [KubernetesContextInfo]
    func useContext(_ name: String) async throws
    func fetchNamespaces() async throws -> [KubernetesNamespaceInfo]
    func fetchPods(namespace: String) async throws -> [KubernetesPodInfo]
    func fetchDeployments(namespace: String) async throws -> [KubernetesDeploymentInfo]
    func fetchServices(namespace: String) async throws -> [KubernetesServiceInfo]
    func fetchConfigMaps(namespace: String) async throws -> [KubernetesConfigMapInfo]
    func fetchSecrets(namespace: String) async throws -> [KubernetesSecretInfo]
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

    func fetchServices(namespace: String) async throws -> [KubernetesServiceInfo] {
        let command = ["get", "services", "-n", namespace, "-o", "json"]
        let result = try await runner.run(arguments: command)
        let decoded = try decode(KubernetesServiceListResponse.self, from: result.stdout, command: command)

        return decoded.items.map { item in
            let spec = item.spec
            let primaryAddress = spec.externalName
                ?? spec.clusterIPs?.first
                ?? spec.clusterIP
                ?? "-"
            let externalAddress = item.status?.loadBalancer?.ingress?
                .compactMap { $0.hostname ?? $0.ip }
                .first

            return KubernetesServiceInfo(
                name: item.metadata.name,
                type: spec.type ?? "ClusterIP",
                primaryAddress: primaryAddress,
                portCount: spec.ports?.count ?? 0,
                externalAddress: externalAddress
            )
        }
    }

    func fetchConfigMaps(namespace: String) async throws -> [KubernetesConfigMapInfo] {
        let command = ["get", "configmaps", "-n", namespace, "-o", "json"]
        let result = try await runner.run(arguments: command)
        let decoded = try decode(KubernetesConfigMapListResponse.self, from: result.stdout, command: command)

        return decoded.items.map { item in
            KubernetesConfigMapInfo(
                name: item.metadata.name,
                immutable: item.immutable ?? false,
                textData: item.data ?? [:],
                textKeyNames: (item.data?.keys.map { $0 } ?? []).sorted(),
                binaryKeyNames: (item.binaryData?.keys.map { $0 } ?? []).sorted()
            )
        }
    }

    func fetchSecrets(namespace: String) async throws -> [KubernetesSecretInfo] {
        let command = ["get", "secrets", "-n", namespace, "-o", "json"]
        let result = try await runner.run(arguments: command)
        let decoded = try decode(KubernetesSecretListResponse.self, from: result.stdout, command: command)

        return decoded.items.map { item in
            KubernetesSecretInfo(
                name: item.metadata.name,
                type: item.type ?? "Opaque",
                immutable: item.immutable ?? false,
                keyNames: (item.data?.keys.map { $0 } ?? []).sorted(),
                encodedData: item.data ?? [:]
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
