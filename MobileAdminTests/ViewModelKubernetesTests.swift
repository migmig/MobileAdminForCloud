import Testing
import Foundation
@testable import MobileAdmin

final class StubKubernetesService: KubernetesServicing {
    var currentContext: String
    var contexts: [KubernetesContextInfo]
    var namespaces: [KubernetesNamespaceInfo]
    var pods: [KubernetesPodInfo]
    var deployments: [KubernetesDeploymentInfo]
    var services: [KubernetesServiceInfo]
    var configMaps: [KubernetesConfigMapInfo]
    var secrets: [KubernetesSecretInfo]
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
        services: [KubernetesServiceInfo] = [],
            configMaps: [KubernetesConfigMapInfo] = [],
        secrets: [KubernetesSecretInfo] = [],
        logs: String = ""
    ) {
        self.currentContext = currentContext
        self.contexts = contexts
        self.namespaces = namespaces
        self.pods = pods
        self.deployments = deployments
        self.services = services
        self.configMaps = configMaps
        self.secrets = secrets
        self.logs = logs
    }

    func checkAvailability() async throws {}
    func fetchCurrentContext() async throws -> String { currentContext }
    func fetchContexts() async throws -> [KubernetesContextInfo] { contexts }
    func useContext(_ name: String) async throws { switchedContexts.append(name); currentContext = name }
    func fetchNamespaces() async throws -> [KubernetesNamespaceInfo] { namespaces }
    func fetchPods(namespace: String) async throws -> [KubernetesPodInfo] { pods }
    func fetchDeployments(namespace: String) async throws -> [KubernetesDeploymentInfo] { deployments }
    func fetchServices(namespace: String) async throws -> [KubernetesServiceInfo] { services }
    func fetchConfigMaps(namespace: String) async throws -> [KubernetesConfigMapInfo] { configMaps }
    func fetchSecrets(namespace: String) async throws -> [KubernetesSecretInfo] { secrets }
    func fetchPodLogs(name: String, namespace: String) async throws -> String { logs }
    func scaleDeployment(name: String, namespace: String, replicas: Int) async throws { scaledDeployments.append((namespace, name, replicas)) }
    func rolloutRestartDeployment(name: String, namespace: String) async throws { restartedDeployments.append((namespace, name)) }
    func deletePod(name: String, namespace: String) async throws { deletedPods.append((namespace, name)) }
}

struct ViewModelKubernetesTests {
    @Test func refreshKubernetesOverview_updatesContextNamespacePodsAndDeployments() async {
        let service = StubKubernetesService(
            currentContext: "prod-cluster",
            contexts: [KubernetesContextInfo(name: "prod-cluster")],
            namespaces: [KubernetesNamespaceInfo(name: "prod")],
            pods: [KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)],
            deployments: [KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)],
            services: [KubernetesServiceInfo(name: "api", type: "ClusterIP", primaryAddress: "10.0.0.12", portCount: 2, externalAddress: nil)],
            configMaps: [KubernetesConfigMapInfo(name: "app-config", immutable: false, textData: ["A": "1"], textKeyNames: ["A"], binaryKeyNames: [])],
            secrets: [KubernetesSecretInfo(name: "app-secret", type: "Opaque", immutable: false, keyNames: ["token"])]
        )
        let viewModel = ViewModel(kubernetesService: service)

        await viewModel.refreshKubernetesOverview()

        #expect(viewModel.selectedKubeContext == "prod-cluster")
        #expect(viewModel.selectedKubeNamespace == "prod")
        #expect(viewModel.kubePods.map(\.name) == ["api-123"])
        #expect(viewModel.kubeDeployments.map(\.name) == ["api"])
        #expect(viewModel.kubeServices.map(\.name) == ["api"])
        #expect(viewModel.kubeConfigMaps.map(\.name) == ["app-config"])
        #expect(viewModel.kubeSecrets.map(\.name) == ["app-secret"])
        #expect(viewModel.isKubectlAvailable == true)
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

    @Test func refreshPodLogs_afterSelectingPod_updatesSelectedPodLogs() async {
        let service = StubKubernetesService(logs: "ready\nserving")
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)

        await viewModel.refreshPodLogs()

        #expect(viewModel.selectedPodLogs == "ready\nserving")
    }
}
