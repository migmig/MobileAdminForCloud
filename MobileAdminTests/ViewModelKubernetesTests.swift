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
    var rolloutStatus: String
    var events: [KubernetesEventInfo]
    var logs: String
    var deletedPods: [(namespace: String, name: String)] = []
    var scaledDeployments: [(namespace: String, name: String, replicas: Int)] = []
    var restartedDeployments: [(namespace: String, name: String)] = []
    var switchedContexts: [String] = []
    var fetchedRolloutStatuses: [(namespace: String, name: String)] = []
    var fetchedEventsRequests: [(namespace: String, resourceKind: String, resourceName: String)] = []
    var useContextError: Error?
    var rolloutStatusError: Error?
    var eventsError: Error?
    var checkAvailabilityError: Error?
    var podLogsError: Error?

    init(
        currentContext: String = "",
        contexts: [KubernetesContextInfo] = [],
        namespaces: [KubernetesNamespaceInfo] = [],
        pods: [KubernetesPodInfo] = [],
        deployments: [KubernetesDeploymentInfo] = [],
        services: [KubernetesServiceInfo] = [],
            configMaps: [KubernetesConfigMapInfo] = [],
        secrets: [KubernetesSecretInfo] = [],
        rolloutStatus: String = "",
        events: [KubernetesEventInfo] = [],
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
        self.rolloutStatus = rolloutStatus
        self.events = events
        self.logs = logs
    }

    func checkAvailability() async throws {
        if let checkAvailabilityError { throw checkAvailabilityError }
    }
    func fetchCurrentContext() async throws -> String { currentContext }
    func fetchContexts() async throws -> [KubernetesContextInfo] { contexts }
    func useContext(_ name: String) async throws {
        if let useContextError { throw useContextError }
        switchedContexts.append(name)
        currentContext = name
    }
    func fetchNamespaces() async throws -> [KubernetesNamespaceInfo] { namespaces }
    func fetchPods(namespace: String) async throws -> [KubernetesPodInfo] { pods }
    func fetchDeployments(namespace: String) async throws -> [KubernetesDeploymentInfo] { deployments }
    func fetchServices(namespace: String) async throws -> [KubernetesServiceInfo] { services }
    func fetchConfigMaps(namespace: String) async throws -> [KubernetesConfigMapInfo] { configMaps }
    func fetchSecrets(namespace: String) async throws -> [KubernetesSecretInfo] { secrets }
    func fetchRolloutStatus(deployment: String, namespace: String) async throws -> String {
        if let rolloutStatusError { throw rolloutStatusError }
        fetchedRolloutStatuses.append((namespace, deployment))
        return rolloutStatus
    }
    func fetchEvents(namespace: String, resourceKind: String, resourceName: String) async throws -> [KubernetesEventInfo] {
        if let eventsError { throw eventsError }
        fetchedEventsRequests.append((namespace, resourceKind, resourceName))
        return events
    }
    func fetchPodLogs(name: String, namespace: String) async throws -> String {
        if let podLogsError { throw podLogsError }
        return logs
    }
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

    @Test func loadSelectedDeploymentOperationalDetails_setsRolloutStatusAndEvents() async {
        let service = StubKubernetesService(
            rolloutStatus: "deployment \"api\" successfully rolled out",
            events: [KubernetesEventInfo(type: "Normal", reason: "Started", message: "Started container", involvedKind: "Deployment", involvedName: "api", timestampText: "2026-03-29T10:00:00Z")]
        )
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)

        await viewModel.loadSelectedDeploymentOperationalDetails()

        #expect(viewModel.selectedRolloutStatus == "deployment \"api\" successfully rolled out")
        #expect(viewModel.kubeEvents.map(\.reason) == ["Started"])
        #expect(service.fetchedRolloutStatuses == [(namespace: "prod", name: "api")])
        #expect(service.fetchedEventsRequests == [(namespace: "prod", resourceKind: "Deployment", resourceName: "api")])
    }

    @Test func loadSelectedPodOperationalDetails_setsEventsAndClearsRolloutStatus() async {
        let service = StubKubernetesService(
            events: [KubernetesEventInfo(type: "Warning", reason: "BackOff", message: "Back-off restarting failed container", involvedKind: "Pod", involvedName: "api-123", timestampText: "2026-03-29T11:00:00Z")]
        )
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedRolloutStatus = "old rollout"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)

        await viewModel.loadSelectedPodOperationalDetails()

        #expect(viewModel.selectedRolloutStatus.isEmpty)
        #expect(viewModel.kubeEvents.map(\.reason) == ["BackOff"])
        #expect(service.fetchedEventsRequests == [(namespace: "prod", resourceKind: "Pod", resourceName: "api-123")])
    }

    @Test func refreshKubernetesOverview_clearsStaleRolloutAndEventsOnNamespaceChange() async {
        let service = StubKubernetesService(
            currentContext: "prod-cluster",
            contexts: [KubernetesContextInfo(name: "prod-cluster")],
            namespaces: [KubernetesNamespaceInfo(name: "prod")]
        )
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "stale"
        viewModel.selectedRolloutStatus = "old rollout"
        viewModel.kubeEvents = [KubernetesEventInfo(type: "Warning", reason: "BackOff", message: "Old event", involvedKind: "Pod", involvedName: "old-pod", timestampText: "2026-03-29T09:00:00Z")]

        await viewModel.refreshKubernetesOverview()

        #expect(viewModel.selectedKubeNamespace == "prod")
        #expect(viewModel.selectedRolloutStatus.isEmpty)
        #expect(viewModel.kubeEvents.isEmpty)
    }

    @Test func loadSelectedDeploymentOperationalDetails_whenEventsFail_clearsRolloutAndEvents_setsError_stopsLoading() async {
        let service = StubKubernetesService(
            rolloutStatus: "deployment \"api\" successfully rolled out",
            events: []
        )
        service.eventsError = KubernetesCommandError.commandFailed(stderr: "events failed", exitCode: 1, command: "kubectl get events")
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)
        viewModel.selectedRolloutStatus = "old rollout"
        viewModel.kubeEvents = [KubernetesEventInfo(type: "Warning", reason: "Old", message: "old", involvedKind: "Deployment", involvedName: "api", timestampText: "2026-03-29T09:00:00Z")]

        await viewModel.loadSelectedDeploymentOperationalDetails()

        #expect(viewModel.selectedRolloutStatus.isEmpty)
        #expect(viewModel.kubeEvents.isEmpty)
        #expect(viewModel.kubernetesError?.contains("events failed") == true)
        #expect(viewModel.isKubernetesActionLoading == false)
    }

    @Test func loadSelectedPodOperationalDetails_whenEventsFail_clearsEvents_setsError_stopsLoading() async {
        let service = StubKubernetesService(events: [])
        service.eventsError = KubernetesCommandError.commandFailed(stderr: "pod events failed", exitCode: 1, command: "kubectl get events")
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)
        viewModel.kubeEvents = [KubernetesEventInfo(type: "Warning", reason: "Old", message: "old", involvedKind: "Pod", involvedName: "api-123", timestampText: "2026-03-29T09:00:00Z")]

        await viewModel.loadSelectedPodOperationalDetails()

        #expect(viewModel.kubeEvents.isEmpty)
        #expect(viewModel.kubernetesError?.contains("pod events failed") == true)
        #expect(viewModel.isKubernetesActionLoading == false)
    }

    @Test func switchKubernetesContext_clearsSelectionsAndPodLogs_beforeRefresh() async {
        let service = StubKubernetesService(currentContext: "prod-cluster")
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)
        viewModel.selectedKubeService = KubernetesServiceInfo(name: "api", type: "ClusterIP", primaryAddress: "10.0.0.12", portCount: 1, externalAddress: nil)
        viewModel.selectedKubeConfigMap = KubernetesConfigMapInfo(name: "app-config", immutable: false, textData: ["A": "1"], textKeyNames: ["A"], binaryKeyNames: [])
        viewModel.selectedKubeSecret = KubernetesSecretInfo(name: "app-secret", type: "Opaque", immutable: false, keyNames: ["token"])
        viewModel.selectedPodLogs = "stale logs"

        await viewModel.switchKubernetesContext(to: "prod-cluster")

        #expect(viewModel.selectedKubePod == nil)
        #expect(viewModel.selectedKubeDeployment == nil)
        #expect(viewModel.selectedKubeService == nil)
        #expect(viewModel.selectedKubeConfigMap == nil)
        #expect(viewModel.selectedKubeSecret == nil)
        #expect(viewModel.selectedPodLogs.isEmpty)
    }

    @Test func switchKubernetesContext_whenUseContextFails_keepsPreviousContextAndSetsError() async {
        let service = StubKubernetesService(currentContext: "dev-cluster")
        service.useContextError = KubernetesCommandError.commandFailed(stderr: "use-context failed", exitCode: 1, command: "kubectl config use-context prod")
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeContext = "dev-cluster"

        await viewModel.switchKubernetesContext(to: "prod-cluster")

        #expect(viewModel.selectedKubeContext == "dev-cluster")
        #expect(viewModel.kubernetesError?.contains("use-context failed") == true)
    }

    @Test func refreshKubernetesOverview_whenAvailabilityFails_clearsResourceListsAndSetsError() async {
        let service = StubKubernetesService(
            currentContext: "prod-cluster",
            contexts: [KubernetesContextInfo(name: "prod-cluster")],
            namespaces: [KubernetesNamespaceInfo(name: "prod")],
            pods: [KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)],
            deployments: [KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)],
            services: [KubernetesServiceInfo(name: "api", type: "ClusterIP", primaryAddress: "10.0.0.12", portCount: 1, externalAddress: nil)],
            configMaps: [KubernetesConfigMapInfo(name: "app-config", immutable: false, textData: ["A": "1"], textKeyNames: ["A"], binaryKeyNames: [])],
            secrets: [KubernetesSecretInfo(name: "app-secret", type: "Opaque", immutable: false, keyNames: ["token"])]
        )
        service.checkAvailabilityError = KubernetesCommandError.kubectlNotInstalled
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.kubeContexts = [KubernetesContextInfo(name: "stale-context")]
        viewModel.kubeNamespaces = [KubernetesNamespaceInfo(name: "stale-ns")]
        viewModel.kubePods = [KubernetesPodInfo(name: "stale-pod", phase: "Failed", containerCount: 1, readyCount: 0)]
        viewModel.kubeDeployments = [KubernetesDeploymentInfo(name: "stale-deploy", replicas: 1, readyReplicas: 0, availableReplicas: 0)]
        viewModel.kubeServices = [KubernetesServiceInfo(name: "stale-service", type: "ClusterIP", primaryAddress: "10.0.0.9", portCount: 1, externalAddress: nil)]
        viewModel.kubeConfigMaps = [KubernetesConfigMapInfo(name: "stale-cm", immutable: false, textData: [:], textKeyNames: [], binaryKeyNames: [])]
        viewModel.kubeSecrets = [KubernetesSecretInfo(name: "stale-secret", type: "Opaque", immutable: false, keyNames: ["token"])]

        await viewModel.refreshKubernetesOverview()

        #expect(viewModel.isKubectlAvailable == false)
        #expect(viewModel.kubeContexts.isEmpty)
        #expect(viewModel.kubeNamespaces.isEmpty)
        #expect(viewModel.kubePods.isEmpty)
        #expect(viewModel.kubeDeployments.isEmpty)
        #expect(viewModel.kubeServices.isEmpty)
        #expect(viewModel.kubeConfigMaps.isEmpty)
        #expect(viewModel.kubeSecrets.isEmpty)
        #expect(viewModel.kubernetesError?.contains("kubectl") == true)
    }

    @Test func refreshPodLogs_whenFetchFails_clearsStaleLogsAndSetsError() async {
        let service = StubKubernetesService(logs: "")
        service.podLogsError = KubernetesCommandError.commandFailed(stderr: "log fetch failed", exitCode: 1, command: "kubectl logs api-123")
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)
        viewModel.selectedPodLogs = "stale logs"

        await viewModel.refreshPodLogs()

        #expect(viewModel.selectedPodLogs.isEmpty)
        #expect(viewModel.kubernetesError?.contains("log fetch failed") == true)
    }
}
