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
    var currentContextError: Error?
    var rolloutStatusError: Error?
    var eventsError: Error?
    var checkAvailabilityError: Error?
    var podLogsError: Error?
    var scaleDeploymentError: Error?
    var rolloutRestartError: Error?
    var deletePodError: Error?
    var deletePodDelayNanoseconds: UInt64 = 0
    var podDescribeText: String = ""
    var deploymentDescribeText: String = ""
    var resourceYAMLText: String = ""
    var fetchedPodDescribeRequests: [(namespace: String, name: String)] = []
    var fetchedDeploymentDescribeRequests: [(namespace: String, name: String)] = []
    var fetchedYAMLRequests: [(namespace: String, kind: String, name: String)] = []
    var fetchedPodLogsRequests: [(namespace: String, name: String)] = []

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
    func fetchCurrentContext() async throws -> String {
        if let currentContextError { throw currentContextError }
        return currentContext
    }
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
    func fetchPodDescribe(name: String, namespace: String) async throws -> String {
        fetchedPodDescribeRequests.append((namespace, name))
        return podDescribeText
    }
    func fetchDeploymentDescribe(name: String, namespace: String) async throws -> String {
        fetchedDeploymentDescribeRequests.append((namespace, name))
        return deploymentDescribeText
    }
    func fetchResourceYAML(kind: String, name: String, namespace: String) async throws -> String {
        fetchedYAMLRequests.append((namespace, kind, name))
        return resourceYAMLText
    }
    func fetchPodLogs(name: String, namespace: String) async throws -> String {
        if let podLogsError { throw podLogsError }
        fetchedPodLogsRequests.append((namespace, name))
        return logs
    }
    func scaleDeployment(name: String, namespace: String, replicas: Int) async throws {
        if let scaleDeploymentError { throw scaleDeploymentError }
        scaledDeployments.append((namespace, name, replicas))
    }
    func rolloutRestartDeployment(name: String, namespace: String) async throws {
        if let rolloutRestartError { throw rolloutRestartError }
        restartedDeployments.append((namespace, name))
    }
    func deletePod(name: String, namespace: String) async throws {
        if deletePodDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: deletePodDelayNanoseconds)
        }
        if let deletePodError { throw deletePodError }
        deletedPods.append((namespace, name))
    }
}

struct ViewModelKubernetesTests {
    @Test func scaleSelectedDeployment_recordsSuccessResultAndRollbackGuidance_andAudits() async throws {
        let service = StubKubernetesService()
        var auditEntries: [KubernetesActionAuditEntry] = []
        let viewModel = ViewModel(
            kubernetesService: service,
            kubernetesActionAuditSink: { auditEntries.append($0) }
        )
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)

        try await viewModel.scaleSelectedDeployment(to: 5)

        #expect(service.scaledDeployments.count == 1)
        #expect(service.scaledDeployments.first?.namespace == "prod")
        #expect(service.scaledDeployments.first?.name == "api")
        #expect(service.scaledDeployments.first?.replicas == 5)
        #expect(viewModel.pendingKubernetesActionSummary == nil)
        #expect(viewModel.latestKubernetesActionGuidance?.contains("3") == true)
        #expect(viewModel.latestKubernetesActionResult?.actionType == "scale")
        #expect(viewModel.latestKubernetesActionResult?.status == .success)
        #expect(auditEntries.count == 1)
        #expect(auditEntries.first?.actionType == "scale")
        #expect(auditEntries.first?.resourceKind == "Deployment")
        #expect(auditEntries.first?.resourceName == "api")
        #expect(auditEntries.first?.namespace == "prod")
        #expect(auditEntries.first?.requestedValue == "5")
        #expect(auditEntries.first?.previousValue == "3")
        #expect(auditEntries.first?.result == "success")
        #expect(auditEntries.first?.rollbackGuidance?.contains("3") == true)
    }

    @Test func restartSelectedDeployment_whenFails_recordsFailureResultAndAudit() async {
        let service = StubKubernetesService()
        service.rolloutRestartError = KubernetesCommandError.commandFailed(
            stderr: "restart failed",
            exitCode: 1,
            command: "kubectl rollout restart deployment/api"
        )
        var auditEntries: [KubernetesActionAuditEntry] = []
        let viewModel = ViewModel(
            kubernetesService: service,
            kubernetesActionAuditSink: { auditEntries.append($0) }
        )
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)

        do {
            try await viewModel.restartSelectedDeployment()
            Issue.record("Expected rollout restart to fail")
        } catch {
            #expect(error.localizedDescription.contains("restart failed") == true)
        }

        #expect(viewModel.pendingKubernetesActionSummary == nil)
        #expect(viewModel.latestKubernetesActionResult?.actionType == "rollout-restart")
        #expect(viewModel.latestKubernetesActionResult?.status == .failure)
        #expect(viewModel.latestKubernetesActionGuidance?.contains("rollout status") == true)
        #expect(auditEntries.count == 1)
        #expect(auditEntries.first?.result == "failure")
        #expect(auditEntries.first?.errorSummary?.contains("restart failed") == true)
        #expect(auditEntries.first?.rollbackGuidance?.contains("rollout status") == true)
    }

    @Test func deleteSelectedPod_whenCancelled_recordsCancelledResultAndAudit() async {
        let service = StubKubernetesService()
        service.deletePodDelayNanoseconds = 500_000_000
        var auditEntries: [KubernetesActionAuditEntry] = []
        let viewModel = ViewModel(
            kubernetesService: service,
            kubernetesActionAuditSink: { auditEntries.append($0) }
        )
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)

        let deleteTask = Task {
            try await viewModel.deleteSelectedPod()
        }
        deleteTask.cancel()

        let wasCancelled: Bool
        do {
            try await deleteTask.value
            Issue.record("Expected delete pod action to be cancelled")
            wasCancelled = false
        } catch is CancellationError {
            wasCancelled = true
        } catch {
            Issue.record("Expected CancellationError, got: \(error)")
            wasCancelled = false
        }

        #expect(wasCancelled == true)
        #expect(service.deletedPods.isEmpty)
        #expect(viewModel.pendingKubernetesActionSummary == nil)
        #expect(viewModel.latestKubernetesActionResult?.actionType == "delete-pod")
        #expect(viewModel.latestKubernetesActionResult?.status == .cancelled)
        #expect(viewModel.latestKubernetesActionGuidance?.contains("controller") == true)
        #expect(auditEntries.count == 1)
        #expect(auditEntries.first?.actionType == "delete-pod")
        #expect(auditEntries.first?.result == "cancelled")
        #expect(auditEntries.first?.rollbackGuidance?.contains("controller") == true)
    }

    @Test func scaleSelectedDeployment_toZero_includesPreviousReplicaRollbackGuidance() async throws {
        let service = StubKubernetesService()
        var auditEntries: [KubernetesActionAuditEntry] = []
        let viewModel = ViewModel(
            kubernetesService: service,
            kubernetesActionAuditSink: { auditEntries.append($0) }
        )
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)

        try await viewModel.scaleSelectedDeployment(to: 0)

        #expect(viewModel.latestKubernetesActionGuidance?.contains("3") == true)
        #expect(auditEntries.first?.requestedValue == "0")
        #expect(auditEntries.first?.previousValue == "3")
        #expect(auditEntries.first?.rollbackGuidance?.contains("3") == true)
    }

    @Test func failedAction_updatesLatestResultAndClearsPendingSummary() async {
        let service = StubKubernetesService()
        service.scaleDeploymentError = KubernetesCommandError.commandFailed(
            stderr: "scale failed",
            exitCode: 1,
            command: "kubectl scale deployment api"
        )
        var auditEntries: [KubernetesActionAuditEntry] = []
        let viewModel = ViewModel(
            kubernetesService: service,
            kubernetesActionAuditSink: { auditEntries.append($0) }
        )
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)

        do {
            try await viewModel.scaleSelectedDeployment(to: 5)
            Issue.record("Expected scale to fail")
        } catch {
            #expect(error.localizedDescription.contains("scale failed") == true)
        }

        #expect(viewModel.pendingKubernetesActionSummary == nil)
        #expect(viewModel.latestKubernetesActionResult?.status == .failure)
        #expect(viewModel.latestKubernetesActionResult?.errorSummary?.contains("scale failed") == true)
        #expect(auditEntries.first?.result == "failure")
    }

    @Test func successfulAction_usesInjectedAuditSink() async throws {
        let service = StubKubernetesService()
        var sinkCalls = 0
        let viewModel = ViewModel(
            kubernetesService: service,
            kubernetesActionAuditSink: { _ in sinkCalls += 1 }
        )
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 2, readyReplicas: 2, availableReplicas: 2)

        try await viewModel.scaleSelectedDeployment(to: 4)

        #expect(sinkCalls == 1)
    }

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

        #expect(service.deletedPods.count == 1)
        #expect(service.deletedPods.first?.namespace == "prod")
        #expect(service.deletedPods.first?.name == "api-123")
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

    @Test func refreshKubernetesOverview_whenCurrentContextFails_keepsContexts_andLeavesSelectionEmpty() async {
        let service = StubKubernetesService(
            contexts: [KubernetesContextInfo(name: "dev-cluster"), KubernetesContextInfo(name: "prod-cluster")],
            namespaces: []
        )
        service.currentContextError = KubernetesCommandError.commandFailed(
            stderr: "current-context is not set",
            exitCode: 1,
            command: "kubectl config current-context"
        )
        let viewModel = ViewModel(kubernetesService: service)

        await viewModel.refreshKubernetesOverview()

        #expect(viewModel.isKubectlAvailable == true)
        #expect(viewModel.kubeContexts.map(\.name) == ["dev-cluster", "prod-cluster"])
        #expect(viewModel.selectedKubeContext.isEmpty)
        #expect(viewModel.kubernetesError?.contains("current-context is not set") == true)
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
        #expect(service.fetchedRolloutStatuses.count == 1)
        #expect(service.fetchedRolloutStatuses.first?.namespace == "prod")
        #expect(service.fetchedRolloutStatuses.first?.name == "api")
        #expect(service.fetchedEventsRequests.count == 1)
        #expect(service.fetchedEventsRequests.first?.namespace == "prod")
        #expect(service.fetchedEventsRequests.first?.resourceKind == "Deployment")
        #expect(service.fetchedEventsRequests.first?.resourceName == "api")
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
        #expect(service.fetchedEventsRequests.count == 1)
        #expect(service.fetchedEventsRequests.first?.namespace == "prod")
        #expect(service.fetchedEventsRequests.first?.resourceKind == "Pod")
        #expect(service.fetchedEventsRequests.first?.resourceName == "api-123")
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

    @Test func loadSelectedPodDocuments_setsDescribeAndYAML() async {
        let service = StubKubernetesService()
        service.podDescribeText = "Name: api-123\nStatus: Running"
        service.resourceYAMLText = "kind: Pod\nmetadata:\n  name: api-123"
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)

        await viewModel.loadSelectedPodDocuments()

        #expect(viewModel.selectedDescribeText == "Name: api-123\nStatus: Running")
        #expect(viewModel.selectedYAMLText == "kind: Pod\nmetadata:\n  name: api-123")
        #expect(service.fetchedPodDescribeRequests.count == 1)
        #expect(service.fetchedPodDescribeRequests.first?.namespace == "prod")
        #expect(service.fetchedPodDescribeRequests.first?.name == "api-123")
        #expect(service.fetchedYAMLRequests.count == 1)
        #expect(service.fetchedYAMLRequests.first?.namespace == "prod")
        #expect(service.fetchedYAMLRequests.first?.kind == "pod")
        #expect(service.fetchedYAMLRequests.first?.name == "api-123")
    }

    @Test func loadSelectedDeploymentDocuments_setsDescribeAndYAML() async {
        let service = StubKubernetesService()
        service.deploymentDescribeText = "Name: api\nReplicas: 3"
        service.resourceYAMLText = "kind: Deployment\nmetadata:\n  name: api"
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)

        await viewModel.loadSelectedDeploymentDocuments()

        #expect(viewModel.selectedDescribeText == "Name: api\nReplicas: 3")
        #expect(viewModel.selectedYAMLText == "kind: Deployment\nmetadata:\n  name: api")
        #expect(service.fetchedDeploymentDescribeRequests.count == 1)
        #expect(service.fetchedDeploymentDescribeRequests.first?.namespace == "prod")
        #expect(service.fetchedDeploymentDescribeRequests.first?.name == "api")
        #expect(service.fetchedYAMLRequests.count == 1)
        #expect(service.fetchedYAMLRequests.first?.namespace == "prod")
        #expect(service.fetchedYAMLRequests.first?.kind == "deployment")
        #expect(service.fetchedYAMLRequests.first?.name == "api")
    }

    @Test func loadSelectedServiceDocuments_setsYAMLAndClearsDescribe() async {
        let service = StubKubernetesService()
        service.resourceYAMLText = "kind: Service\nmetadata:\n  name: api"
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedDescribeText = "stale describe"
        viewModel.selectedKubeService = KubernetesServiceInfo(name: "api", type: "ClusterIP", primaryAddress: "10.0.0.12", portCount: 1, externalAddress: nil)

        await viewModel.loadSelectedServiceDocuments()

        #expect(viewModel.selectedDescribeText.isEmpty)
        #expect(viewModel.selectedYAMLText == "kind: Service\nmetadata:\n  name: api")
        #expect(service.fetchedYAMLRequests.count == 1)
        #expect(service.fetchedYAMLRequests.first?.namespace == "prod")
        #expect(service.fetchedYAMLRequests.first?.kind == "service")
        #expect(service.fetchedYAMLRequests.first?.name == "api")
    }

    @Test func loadSelectedConfigMapDocuments_setsYAMLAndClearsDescribe() async {
        let service = StubKubernetesService()
        service.resourceYAMLText = "kind: ConfigMap\nmetadata:\n  name: app-config"
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedDescribeText = "stale describe"
        viewModel.selectedKubeConfigMap = KubernetesConfigMapInfo(name: "app-config", immutable: false, textData: ["A": "1"], textKeyNames: ["A"], binaryKeyNames: [])

        await viewModel.loadSelectedConfigMapDocuments()

        #expect(viewModel.selectedDescribeText.isEmpty)
        #expect(viewModel.selectedYAMLText == "kind: ConfigMap\nmetadata:\n  name: app-config")
        #expect(service.fetchedYAMLRequests.count == 1)
        #expect(service.fetchedYAMLRequests.first?.namespace == "prod")
        #expect(service.fetchedYAMLRequests.first?.kind == "configmap")
        #expect(service.fetchedYAMLRequests.first?.name == "app-config")
    }

    @Test func loadSelectedSecretDocuments_setsYAMLAndClearsDescribe() async {
        let service = StubKubernetesService()
        service.resourceYAMLText = "kind: Secret\nmetadata:\n  name: app-secret"
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedDescribeText = "stale describe"
        viewModel.selectedKubeSecret = KubernetesSecretInfo(name: "app-secret", type: "Opaque", immutable: false, keyNames: ["token"], encodedData: ["token": "dG9rZW4="])

        await viewModel.loadSelectedSecretDocuments()

        #expect(viewModel.selectedDescribeText.isEmpty)
        #expect(viewModel.selectedYAMLText == "kind: Secret\nmetadata:\n  name: app-secret")
        #expect(service.fetchedYAMLRequests.count == 1)
        #expect(service.fetchedYAMLRequests.first?.namespace == "prod")
        #expect(service.fetchedYAMLRequests.first?.kind == "secret")
        #expect(service.fetchedYAMLRequests.first?.name == "app-secret")
    }

    @Test func refreshKubernetesOverview_clearsStaleDescribeAndYAML() async {
        let service = StubKubernetesService(
            currentContext: "prod-cluster",
            contexts: [KubernetesContextInfo(name: "prod-cluster")],
            namespaces: [KubernetesNamespaceInfo(name: "prod")]
        )
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedDescribeText = "stale describe"
        viewModel.selectedYAMLText = "stale yaml"

        await viewModel.refreshKubernetesOverview()

        #expect(viewModel.selectedDescribeText.isEmpty)
        #expect(viewModel.selectedYAMLText.isEmpty)
    }

    @Test func refreshSelectedOperationsOnce_whenDeploymentSelected_fetchesRolloutAndEvents() async {
        let service = StubKubernetesService(
            rolloutStatus: "deployment \"api\" successfully rolled out",
            events: [KubernetesEventInfo(type: "Normal", reason: "Scaled", message: "Scaled up", involvedKind: "Deployment", involvedName: "api", timestampText: "2026-03-29T10:00:00Z")]
        )
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)

        await viewModel.refreshSelectedOperationsOnce()

        #expect(viewModel.selectedRolloutStatus == "deployment \"api\" successfully rolled out")
        #expect(viewModel.kubeEvents.map(\.reason) == ["Scaled"])
        #expect(service.fetchedRolloutStatuses.count == 1)
        #expect(service.fetchedRolloutStatuses.first?.namespace == "prod")
        #expect(service.fetchedRolloutStatuses.first?.name == "api")
        #expect(service.fetchedEventsRequests.count == 1)
        #expect(service.fetchedEventsRequests.first?.namespace == "prod")
        #expect(service.fetchedEventsRequests.first?.resourceKind == "Deployment")
        #expect(service.fetchedEventsRequests.first?.resourceName == "api")
    }

    @Test func refreshSelectedOperationsOnce_whenPodSelected_fetchesLogsAndEvents() async {
        let service = StubKubernetesService(
            events: [KubernetesEventInfo(type: "Warning", reason: "BackOff", message: "Back-off restarting failed container", involvedKind: "Pod", involvedName: "api-123", timestampText: "2026-03-29T11:00:00Z")],
            logs: "latest logs"
        )
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)

        await viewModel.refreshSelectedOperationsOnce()

        #expect(viewModel.selectedPodLogs == "latest logs")
        #expect(viewModel.kubeEvents.map(\.reason) == ["BackOff"])
        #expect(service.fetchedPodLogsRequests.count == 1)
        #expect(service.fetchedPodLogsRequests.first?.namespace == "prod")
        #expect(service.fetchedPodLogsRequests.first?.name == "api-123")
        #expect(service.fetchedEventsRequests.count == 1)
        #expect(service.fetchedEventsRequests.first?.namespace == "prod")
        #expect(service.fetchedEventsRequests.first?.resourceKind == "Pod")
        #expect(service.fetchedEventsRequests.first?.resourceName == "api-123")
    }

    @Test func startKubernetesAutoRefreshIfNeeded_whenUnsupportedSelection_doesNotRunAndTurnsOffToggle() async {
        let service = StubKubernetesService()
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubeService = KubernetesServiceInfo(name: "api", type: "ClusterIP", primaryAddress: "10.0.0.12", portCount: 1, externalAddress: nil)
        viewModel.isKubernetesAutoRefreshEnabled = true

        await viewModel.startKubernetesAutoRefreshIfNeeded()

        #expect(viewModel.isKubernetesAutoRefreshEnabled == false)
        #expect(viewModel.kubernetesAutoRefreshTask == nil)
        #expect(service.fetchedRolloutStatuses.isEmpty)
        #expect(service.fetchedEventsRequests.isEmpty)
        #expect(service.fetchedPodLogsRequests.isEmpty)
    }

    @Test func stopKubernetesAutoRefresh_resetsToggleAndTask() async {
        let service = StubKubernetesService(logs: "ok")
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)
        viewModel.kubernetesAutoRefreshInterval = 0.05
        viewModel.isKubernetesAutoRefreshEnabled = true

        await viewModel.startKubernetesAutoRefreshIfNeeded()
        #expect(viewModel.kubernetesAutoRefreshTask != nil)

        await viewModel.stopKubernetesAutoRefresh()

        #expect(viewModel.isKubernetesAutoRefreshEnabled == false)
        #expect(viewModel.kubernetesAutoRefreshTask == nil)
    }

    @Test func clearSelectedKubernetesResources_stopsKubernetesAutoRefresh() async {
        let service = StubKubernetesService(logs: "ok")
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)
        viewModel.kubernetesAutoRefreshInterval = 0.05
        viewModel.isKubernetesAutoRefreshEnabled = true

        await viewModel.startKubernetesAutoRefreshIfNeeded()
        #expect(viewModel.kubernetesAutoRefreshTask != nil)

        await viewModel.clearSelectedKubernetesResources()

        #expect(viewModel.isKubernetesAutoRefreshEnabled == false)
        #expect(viewModel.kubernetesAutoRefreshTask == nil)
    }

    @Test func switchKubernetesContext_stopsKubernetesAutoRefresh() async {
        let service = StubKubernetesService(
            currentContext: "dev-cluster",
            contexts: [KubernetesContextInfo(name: "dev-cluster"), KubernetesContextInfo(name: "prod-cluster")],
            namespaces: [KubernetesNamespaceInfo(name: "prod")],
            pods: [KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)]
        )
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "prod"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)
        viewModel.kubernetesAutoRefreshInterval = 0.05
        viewModel.isKubernetesAutoRefreshEnabled = true

        await viewModel.startKubernetesAutoRefreshIfNeeded()
        #expect(viewModel.kubernetesAutoRefreshTask != nil)

        await viewModel.switchKubernetesContext(to: "prod-cluster")

        #expect(viewModel.isKubernetesAutoRefreshEnabled == false)
        #expect(viewModel.kubernetesAutoRefreshTask == nil)
    }

    @Test func refreshKubernetesOverview_whenNamespaceChanges_stopsKubernetesAutoRefresh() async {
        let service = StubKubernetesService(
            currentContext: "prod-cluster",
            contexts: [KubernetesContextInfo(name: "prod-cluster")],
            namespaces: [KubernetesNamespaceInfo(name: "prod")],
            pods: [KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)]
        )
        let viewModel = ViewModel(kubernetesService: service)
        viewModel.selectedKubeNamespace = "stale"
        viewModel.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)
        viewModel.kubernetesAutoRefreshInterval = 0.05
        viewModel.isKubernetesAutoRefreshEnabled = true

        await viewModel.startKubernetesAutoRefreshIfNeeded()
        #expect(viewModel.kubernetesAutoRefreshTask != nil)

        await viewModel.refreshKubernetesOverview()

        #expect(viewModel.selectedKubeNamespace == "prod")
        #expect(viewModel.isKubernetesAutoRefreshEnabled == false)
        #expect(viewModel.kubernetesAutoRefreshTask == nil)
    }
}
