import SwiftUI
import Logging

/// ViewModel facade - 뷰에서 @EnvironmentObject로 접근하는 진입점
/// 실제 비즈니스 로직은 도메인별 서비스로 위임
class ViewModel: ObservableObject {
    struct KubernetesActionResultState: Equatable {
        enum Status: Equatable {
            case success
            case failure
            case cancelled
        }

        let actionType: String
        let resourceKind: String
        let resourceName: String
        let namespace: String
        let status: Status
        let errorSummary: String?
    }

    @Published var buildProjects : [SourceBuildProject] = []
    @Published var errorItems    : [ErrorCloudItem] = []
    @Published var goodsItems    : [Goodsinfo] = []
    @Published var edcCrseCllist : [EdcCrseCl] = []
    @Published var sourceCommitInfoRepository : [SourceCommitInfoRepository] = []
    @Published var sourcePipelineList : [SourceInfoProjectInfo] = []
    @Published var sourcePipelineHistoryList: [SourcePipelineHistoryInfoHistoryList] = []
    @Published var sourceDeployList : [SourceInfoProjectInfo] = []
    @Published var sourceDeployHistoryList : [SourceDeployHistoryInfoHistoryList] = []
    @Published var selectedErrors: Set<Int> = []
    @Published var lastError: NetworkError?
    @Published var kubeContexts: [KubernetesContextInfo] = []
    @Published var selectedKubeContext: String = "" {
        didSet {
            if selectedKubeContext != oldValue {
                stopKubernetesAutoRefreshSync()
            }
        }
    }
    @Published var kubeNamespaces: [KubernetesNamespaceInfo] = []
    @Published var selectedKubeNamespace: String = "" {
        didSet {
            if selectedKubeNamespace != oldValue {
                stopKubernetesAutoRefreshSync()
            }
        }
    }
    @Published var kubePods: [KubernetesPodInfo] = []
    @Published var selectedKubePod: KubernetesPodInfo? {
        didSet {
            if selectedKubePod?.name != oldValue?.name {
                stopKubernetesAutoRefreshSync()
            }
        }
    }
    @Published var kubeDeployments: [KubernetesDeploymentInfo] = []
    @Published var selectedKubeDeployment: KubernetesDeploymentInfo? {
        didSet {
            if selectedKubeDeployment?.name != oldValue?.name {
                stopKubernetesAutoRefreshSync()
            }
        }
    }
    @Published var kubeServices: [KubernetesServiceInfo] = []
    @Published var selectedKubeService: KubernetesServiceInfo? {
        didSet {
            if selectedKubeService?.name != oldValue?.name {
                stopKubernetesAutoRefreshSync()
            }
        }
    }
    @Published var kubeConfigMaps: [KubernetesConfigMapInfo] = []
    @Published var selectedKubeConfigMap: KubernetesConfigMapInfo? {
        didSet {
            if selectedKubeConfigMap?.name != oldValue?.name {
                stopKubernetesAutoRefreshSync()
            }
        }
    }
    @Published var kubeSecrets: [KubernetesSecretInfo] = []
    @Published var selectedKubeSecret: KubernetesSecretInfo? {
        didSet {
            if selectedKubeSecret?.name != oldValue?.name {
                stopKubernetesAutoRefreshSync()
            }
        }
    }
    @Published var selectedPodLogs: String = ""
    @Published var kubeEvents: [KubernetesEventInfo] = []
    @Published var selectedRolloutStatus: String = ""
    @Published var selectedDescribeText: String = ""
    @Published var selectedYAMLText: String = ""
    @Published var kubernetesError: String?
    @Published var isKubernetesLoading = false
    @Published var isKubectlAvailable = false
    @Published var isKubernetesActionLoading = false
    @Published var isKubernetesDocumentLoading = false
    @Published var isKubernetesAutoRefreshEnabled = false
    @Published var kubernetesAutoRefreshInterval: TimeInterval = 5
    @Published var pendingKubernetesActionSummary: String?
    @Published var latestKubernetesActionGuidance: String?
    @Published var latestKubernetesActionResult: KubernetesActionResultState?

    var kubernetesAutoRefreshTask: Task<Void, Never>?

    let logger = Logger(label: "com.migmig.MobileAdmin.ViewModel")
    static var currentServerType: EnvironmentType = EnvironmentConfig.current

    // 하위 호환: 외부에서 ViewModel.token 접근 시 NetworkClient로 위임
    static var token: String? {
        get { NetworkClient.token }
        set { NetworkClient.token = newValue }
    }
    static var tokenExpirationDate: Date? {
        get { NetworkClient.tokenExpirationDate }
        set { NetworkClient.tokenExpirationDate = newValue }
    }

    // MARK: - 서비스

    private let networkClient: NetworkClient
    private let toastService: ToastService
    private let errorService: ErrorService
    private let goodsService: GoodsService
    private let educationService: EducationService
    private let codeService: CodeService
    private let closeDeptService: CloseDeptService
    private let buildService: BuildService
    private let pipelineService: PipelineService
    private let commitService: CommitService
    private let deployService: DeployService
    private let userLogService: UserLogService
    private let kubernetesService: any KubernetesServicing
    private var kubernetesActionAuditSink: @MainActor (KubernetesActionAuditEntry) -> Void

    init(
        kubernetesService: any KubernetesServicing = KubernetesService(),
        kubernetesActionAuditSink: @escaping @MainActor (KubernetesActionAuditEntry) -> Void = { _ in }
    ) {
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
        self.kubernetesActionAuditSink = kubernetesActionAuditSink
    }

    @MainActor
    func configureKubernetesActionAuditSink(_ sink: @escaping @MainActor (KubernetesActionAuditEntry) -> Void) {
        self.kubernetesActionAuditSink = sink
    }

    func setToken(token: String?) {
        networkClient.setToken(token: token)
    }

    // MARK: - Toast API

    func fetchToasts() async -> Toast {
        await toastService.fetchToasts()
    }

    func setNoticeVisible(toastData: Toast) async {
        await toastService.setNoticeVisible(toastData: toastData)
    }

    func setToastData(toastData: Toast) async {
        await toastService.setToastData(toastData: toastData)
    }

    // MARK: - Error Cloud API

    func fetchErrors(startFrom: Date, endTo: Date) async -> [ErrorCloudItem]? {
        await errorService.fetchErrors(startFrom: startFrom, endTo: endTo)
    }

    func deleteError(id: Int) async {
        await errorService.deleteError(id: id)
    }

    // MARK: - Goods API

    func fetchGoods(_ startFrom: Date?, _ endTo: Date?) async -> [Goodsinfo]? {
        await goodsService.fetchGoods(startFrom, endTo)
    }

    // MARK: - 교육과정 API

    func fetchClsLists() async -> EdcCrseClListResponse {
        await educationService.fetchClsLists()
    }

    func fetchClsInfo(edcCrseId: Int) async -> EdcCrseResponse {
        await educationService.fetchClsInfo(edcCrseId: edcCrseId)
    }

    // MARK: - 공통코드 API

    func fetchGroupCodeLists() async -> [CmmnGroupCodeItem] {
        await codeService.fetchGroupCodeLists()
    }

    func fetchCodeListByGroupCode(_ groupCode: String) async -> [CmmnCodeItem] {
        await codeService.fetchCodeListByGroupCode(groupCode)
    }

    // MARK: - 개시마감 API

    func fetchCloseDeptList() async -> CloseInfo {
        await closeDeptService.fetchCloseDeptList()
    }

    // MARK: - Build API

    func fetchSourceBuildList() async -> BuildProjects {
        await buildService.fetchSourceBuildList()
    }

    func fetchSourceBuildInfo(_ buildId: Int) async -> SourceBuildInfo? {
        await buildService.fetchSourceBuildInfo(buildId)
    }

    func execSourceBuild(_ buildId: Int) async -> BuildExecResult? {
        await buildService.execSourceBuild(buildId)
    }

    func fetchSourceBuildHistory(_ buildId: Int) async -> SourceBuildHistoryInfo? {
        await buildService.fetchSourceBuildHistory(buildId)
    }

    // MARK: - Pipeline API

    func fetchSourcePipelineList() async -> SourceProjectInfo {
        await pipelineService.fetchSourcePipelineList()
    }

    func fetchSourcePipelineHistoryInfo(_ projectId: Int) async -> SourcePipelineHistoryInfo {
        await pipelineService.fetchSourcePipelineHistoryInfo(projectId)
    }

    func runSourcePipeline(_ projectId: Int) async -> SourcePipelineExecResult {
        await pipelineService.runSourcePipeline(projectId)
    }

    func cancelSourcePipeline(_ projectId: Int, _ historyId: Int) async -> SourcePipelineExecResult {
        await pipelineService.cancelSourcePipeline(projectId, historyId)
    }

    // MARK: - Commit API

    func fetchSourceCommitList() async -> SourceCommitInfo {
        await commitService.fetchSourceCommitList()
    }

    func fetchSourceCommitBranchList(_ repositoryName: String) async -> SourceCommitBranchInfo {
        await commitService.fetchSourceCommitBranchList(repositoryName)
    }

    // MARK: - Deploy API

    func fetchSourceDeployList() async -> SourceProjectInfo {
        await deployService.fetchSourceDeployList()
    }

    func fetchSourceDeployHistoryInfo(_ projectId: Int) async -> SourceDeployHistoryInfo {
        await deployService.fetchSourceDeployHistoryInfo(projectId)
    }

    func fetchSourceDeployStageInfo(_ projectId: Int) async -> SourceDeployStageInfo {
        await deployService.fetchSourceDeployStageInfo(projectId)
    }

    func fetchSourceDeployScenarioInfo(_ projectId: Int, _ stageId: Int) async -> SourceDeployScenarioInfo {
        await deployService.fetchSourceDeployScenarioInfo(projectId, stageId)
    }

    func runSourceDeploy(_ projectId: Int, _ stageId: Int, _ scenarioId: Int) async -> SourceDeployExecResult {
        await deployService.runSourceDeploy(projectId, stageId, scenarioId)
    }

    @MainActor
    func refreshKubernetesOverview() async {
        isKubernetesLoading = true
        defer { isKubernetesLoading = false }
        resetKubernetesOperationalState()
        resetKubernetesDocumentState()

        do {
            try await kubernetesService.checkAvailability()
            isKubectlAvailable = true
            kubeContexts = try await kubernetesService.fetchContexts()

            do {
                selectedKubeContext = try await kubernetesService.fetchCurrentContext()
            } catch {
                selectedKubeContext = ""
                kubeNamespaces = []
                kubePods = []
                kubeDeployments = []
                kubeServices = []
                kubeConfigMaps = []
                kubeSecrets = []
                clearSelectedKubernetesResources()
                kubernetesError = error.localizedDescription
                return
            }

            kubeNamespaces = try await kubernetesService.fetchNamespaces()

            if selectedKubeNamespace.isEmpty || !kubeNamespaces.contains(where: { $0.name == selectedKubeNamespace }) {
                selectedKubeNamespace = kubeNamespaces.first?.name ?? ""
            }

            if !selectedKubeNamespace.isEmpty {
                kubePods = try await kubernetesService.fetchPods(namespace: selectedKubeNamespace)
                kubeDeployments = try await kubernetesService.fetchDeployments(namespace: selectedKubeNamespace)
                kubeServices = try await kubernetesService.fetchServices(namespace: selectedKubeNamespace)
                kubeConfigMaps = try await kubernetesService.fetchConfigMaps(namespace: selectedKubeNamespace)
                kubeSecrets = try await kubernetesService.fetchSecrets(namespace: selectedKubeNamespace)
            } else {
                kubePods = []
                kubeDeployments = []
                kubeServices = []
                kubeConfigMaps = []
                kubeSecrets = []
            }

            kubernetesError = nil
        } catch {
            isKubectlAvailable = false
            kubeContexts = []
            kubeNamespaces = []
            kubePods = []
            kubeDeployments = []
            kubeServices = []
            kubeConfigMaps = []
            kubeSecrets = []
            clearSelectedKubernetesResources()
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func switchKubernetesContext(to name: String) async {
        let previousContext = selectedKubeContext
        do {
            try await kubernetesService.useContext(name)
            selectedKubeContext = name
            selectedKubeNamespace = ""
            clearSelectedKubernetesResources()
            resetKubernetesOperationalState()
            resetKubernetesDocumentState()
            await refreshKubernetesOverview()
        } catch {
            selectedKubeContext = previousContext
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func clearSelectedKubernetesResources() {
        stopKubernetesAutoRefreshSync()
        selectedKubePod = nil
        selectedKubeDeployment = nil
        selectedKubeService = nil
        selectedKubeConfigMap = nil
        selectedKubeSecret = nil
        selectedPodLogs = ""
        resetKubernetesDocumentState()
    }

    @MainActor
    func resetKubernetesOperationalState() {
        kubeEvents = []
        selectedRolloutStatus = ""
    }

    @MainActor
    func resetKubernetesDocumentState() {
        selectedDescribeText = ""
        selectedYAMLText = ""
    }

    @MainActor
    func loadSelectedDeploymentOperationalDetails() async {
        guard let selectedKubeDeployment else {
            resetKubernetesOperationalState()
            return
        }

        isKubernetesActionLoading = true
        defer { isKubernetesActionLoading = false }
        resetKubernetesOperationalState()

        do {
            selectedRolloutStatus = try await kubernetesService.fetchRolloutStatus(
                deployment: selectedKubeDeployment.name,
                namespace: selectedKubeNamespace
            )
            kubeEvents = try await kubernetesService.fetchEvents(
                namespace: selectedKubeNamespace,
                resourceKind: "Deployment",
                resourceName: selectedKubeDeployment.name
            )
            kubernetesError = nil
        } catch {
            resetKubernetesOperationalState()
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func loadSelectedPodOperationalDetails() async {
        guard let selectedKubePod else {
            resetKubernetesOperationalState()
            return
        }

        isKubernetesActionLoading = true
        defer { isKubernetesActionLoading = false }
        resetKubernetesOperationalState()

        do {
            kubeEvents = try await kubernetesService.fetchEvents(
                namespace: selectedKubeNamespace,
                resourceKind: "Pod",
                resourceName: selectedKubePod.name
            )
            kubernetesError = nil
        } catch {
            resetKubernetesOperationalState()
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func loadSelectedPodDocuments() async {
        guard let selectedKubePod else {
            resetKubernetesDocumentState()
            return
        }

        isKubernetesDocumentLoading = true
        defer { isKubernetesDocumentLoading = false }
        resetKubernetesDocumentState()

        do {
            selectedDescribeText = try await kubernetesService.fetchPodDescribe(name: selectedKubePod.name, namespace: selectedKubeNamespace)
            selectedYAMLText = try await kubernetesService.fetchResourceYAML(kind: "pod", name: selectedKubePod.name, namespace: selectedKubeNamespace)
            kubernetesError = nil
        } catch {
            resetKubernetesDocumentState()
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func loadSelectedDeploymentDocuments() async {
        guard let selectedKubeDeployment else {
            resetKubernetesDocumentState()
            return
        }

        isKubernetesDocumentLoading = true
        defer { isKubernetesDocumentLoading = false }
        resetKubernetesDocumentState()

        do {
            selectedDescribeText = try await kubernetesService.fetchDeploymentDescribe(name: selectedKubeDeployment.name, namespace: selectedKubeNamespace)
            selectedYAMLText = try await kubernetesService.fetchResourceYAML(kind: "deployment", name: selectedKubeDeployment.name, namespace: selectedKubeNamespace)
            kubernetesError = nil
        } catch {
            resetKubernetesDocumentState()
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func loadSelectedServiceDocuments() async {
        guard let selectedKubeService else {
            resetKubernetesDocumentState()
            return
        }

        isKubernetesDocumentLoading = true
        defer { isKubernetesDocumentLoading = false }
        resetKubernetesDocumentState()

        do {
            selectedYAMLText = try await kubernetesService.fetchResourceYAML(kind: "service", name: selectedKubeService.name, namespace: selectedKubeNamespace)
            kubernetesError = nil
        } catch {
            resetKubernetesDocumentState()
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func loadSelectedConfigMapDocuments() async {
        guard let selectedKubeConfigMap else {
            resetKubernetesDocumentState()
            return
        }

        isKubernetesDocumentLoading = true
        defer { isKubernetesDocumentLoading = false }
        resetKubernetesDocumentState()

        do {
            selectedYAMLText = try await kubernetesService.fetchResourceYAML(kind: "configmap", name: selectedKubeConfigMap.name, namespace: selectedKubeNamespace)
            kubernetesError = nil
        } catch {
            resetKubernetesDocumentState()
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func loadSelectedSecretDocuments() async {
        guard let selectedKubeSecret else {
            resetKubernetesDocumentState()
            return
        }

        isKubernetesDocumentLoading = true
        defer { isKubernetesDocumentLoading = false }
        resetKubernetesDocumentState()

        do {
            selectedYAMLText = try await kubernetesService.fetchResourceYAML(kind: "secret", name: selectedKubeSecret.name, namespace: selectedKubeNamespace)
            kubernetesError = nil
        } catch {
            resetKubernetesDocumentState()
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func refreshPodLogs() async {
        guard let selectedKubePod else { return }

        do {
            selectedPodLogs = try await kubernetesService.fetchPodLogs(name: selectedKubePod.name, namespace: selectedKubeNamespace)
            kubernetesError = nil
        } catch {
            selectedPodLogs = ""
            kubernetesError = error.localizedDescription
        }
    }

    @MainActor
    func refreshSelectedOperationsOnce() async {
        switch kubernetesOperationalRefreshTarget {
        case .deployment:
            await loadSelectedDeploymentOperationalDetails()
        case .pod:
            await refreshPodLogs()
            await loadSelectedPodOperationalDetails()
        case .unsupported, .none:
            resetKubernetesOperationalState()
        }
    }

    @MainActor
    func startKubernetesAutoRefreshIfNeeded() async {
        if !isKubernetesAutoRefreshEnabled {
            stopKubernetesAutoRefreshSync(resetToggle: false)
            return
        }

        guard canAutoRefreshSelectedOperations else {
            stopKubernetesAutoRefreshSync()
            return
        }

        stopKubernetesAutoRefreshSync(resetToggle: false)

        let intervalSeconds = max(kubernetesAutoRefreshInterval, 0.1)
        kubernetesAutoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }

                let shouldContinue = await MainActor.run {
                    self.isKubernetesAutoRefreshEnabled && self.canAutoRefreshSelectedOperations
                }

                if !shouldContinue { break }

                await self.refreshSelectedOperationsOnce()

                do {
                    try await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
                } catch {
                    break
                }
            }

            await MainActor.run {
                self?.kubernetesAutoRefreshTask = nil
            }
        }
    }

    @MainActor
    func stopKubernetesAutoRefresh() {
        stopKubernetesAutoRefreshSync()
    }

    private enum KubernetesOperationalRefreshTarget {
        case deployment
        case pod
        case unsupported
        case none
    }

    @MainActor
    private var kubernetesOperationalRefreshTarget: KubernetesOperationalRefreshTarget {
        if selectedKubeDeployment != nil {
            return .deployment
        }

        if selectedKubePod != nil {
            return .pod
        }

        if selectedKubeService != nil || selectedKubeConfigMap != nil || selectedKubeSecret != nil {
            return .unsupported
        }

        return .none
    }

    @MainActor
    private var canAutoRefreshSelectedOperations: Bool {
        switch kubernetesOperationalRefreshTarget {
        case .deployment, .pod:
            return true
        case .unsupported, .none:
            return false
        }
    }

    private func stopKubernetesAutoRefreshSync(resetToggle: Bool = true) {
        if resetToggle {
            isKubernetesAutoRefreshEnabled = false
        }
        kubernetesAutoRefreshTask?.cancel()
        kubernetesAutoRefreshTask = nil
    }

    @MainActor
    func scaleSelectedDeployment(to replicas: Int) async throws {
        guard let selectedKubeDeployment else { return }

        let previousReplicasText: String? = "\(selectedKubeDeployment.replicas)"
        let rollbackGuidance = scaleRollbackGuidance(previousReplicas: previousReplicasText)

        try await runKubernetesMutationAction(
            actionType: "scale",
            resourceKind: "Deployment",
            resourceName: selectedKubeDeployment.name,
            namespace: selectedKubeNamespace,
            requestedValue: "\(replicas)",
            previousValue: previousReplicasText,
            rollbackGuidance: rollbackGuidance,
            pendingSummary: "Scaling deployment \(selectedKubeDeployment.name) to \(replicas) replicas"
        ) {
            try await kubernetesService.scaleDeployment(
                name: selectedKubeDeployment.name,
                namespace: selectedKubeNamespace,
                replicas: replicas
            )
        }
    }

    @MainActor
    func restartSelectedDeployment() async throws {
        guard let selectedKubeDeployment else { return }

        let rollbackGuidance = rolloutRestartRollbackGuidance

        try await runKubernetesMutationAction(
            actionType: "rollout-restart",
            resourceKind: "Deployment",
            resourceName: selectedKubeDeployment.name,
            namespace: selectedKubeNamespace,
            requestedValue: nil,
            previousValue: nil,
            rollbackGuidance: rollbackGuidance,
            pendingSummary: "Restarting rollout for deployment \(selectedKubeDeployment.name)"
        ) {
            try await kubernetesService.rolloutRestartDeployment(
                name: selectedKubeDeployment.name,
                namespace: selectedKubeNamespace
            )
        }
    }

    @MainActor
    func deleteSelectedPod() async throws {
        guard let selectedKubePod else { return }

        let rollbackGuidance = deletePodRollbackGuidance

        try await runKubernetesMutationAction(
            actionType: "delete-pod",
            resourceKind: "Pod",
            resourceName: selectedKubePod.name,
            namespace: selectedKubeNamespace,
            requestedValue: nil,
            previousValue: nil,
            rollbackGuidance: rollbackGuidance,
            pendingSummary: "Deleting pod \(selectedKubePod.name)"
        ) {
            try await kubernetesService.deletePod(name: selectedKubePod.name, namespace: selectedKubeNamespace)
        }
    }

    @MainActor
    private func runKubernetesMutationAction(
        actionType: String,
        resourceKind: String,
        resourceName: String,
        namespace: String,
        requestedValue: String?,
        previousValue: String?,
        rollbackGuidance: String,
        pendingSummary: String,
        operation: () async throws -> Void
    ) async throws {
        pendingKubernetesActionSummary = pendingSummary
        latestKubernetesActionGuidance = nil
        isKubernetesActionLoading = true

        defer {
            pendingKubernetesActionSummary = nil
            isKubernetesActionLoading = false
        }

        do {
            try Task.checkCancellation()
            try await operation()

            latestKubernetesActionGuidance = rollbackGuidance
            latestKubernetesActionResult = KubernetesActionResultState(
                actionType: actionType,
                resourceKind: resourceKind,
                resourceName: resourceName,
                namespace: namespace,
                status: .success,
                errorSummary: nil
            )
            kubernetesError = nil

            kubernetesActionAuditSink(
                KubernetesActionAuditEntry(
                    actionType: actionType,
                    resourceKind: resourceKind,
                    resourceName: resourceName,
                    namespace: namespace,
                    requestedValue: requestedValue,
                    previousValue: previousValue,
                    result: "success",
                    rollbackGuidance: rollbackGuidance,
                    actorLabel: kubernetesActorLabel
                )
            )
        } catch is CancellationError {
            latestKubernetesActionGuidance = rollbackGuidance
            latestKubernetesActionResult = KubernetesActionResultState(
                actionType: actionType,
                resourceKind: resourceKind,
                resourceName: resourceName,
                namespace: namespace,
                status: .cancelled,
                errorSummary: nil
            )

            kubernetesActionAuditSink(
                KubernetesActionAuditEntry(
                    actionType: actionType,
                    resourceKind: resourceKind,
                    resourceName: resourceName,
                    namespace: namespace,
                    requestedValue: requestedValue,
                    previousValue: previousValue,
                    result: "cancelled",
                    rollbackGuidance: rollbackGuidance,
                    actorLabel: kubernetesActorLabel
                )
            )
            throw CancellationError()
        } catch {
            let errorSummary = error.localizedDescription
            latestKubernetesActionGuidance = rollbackGuidance
            latestKubernetesActionResult = KubernetesActionResultState(
                actionType: actionType,
                resourceKind: resourceKind,
                resourceName: resourceName,
                namespace: namespace,
                status: .failure,
                errorSummary: errorSummary
            )
            kubernetesError = errorSummary

            kubernetesActionAuditSink(
                KubernetesActionAuditEntry(
                    actionType: actionType,
                    resourceKind: resourceKind,
                    resourceName: resourceName,
                    namespace: namespace,
                    requestedValue: requestedValue,
                    previousValue: previousValue,
                    result: "failure",
                    errorSummary: errorSummary,
                    rollbackGuidance: rollbackGuidance,
                    actorLabel: kubernetesActorLabel
                )
            )
            throw error
        }
    }

    @MainActor
    private var rolloutRestartRollbackGuidance: String {
        "No direct undo is available for rollout restart. Check rollout status/events and perform a known image/config rollout if recovery is needed."
    }

    @MainActor
    private var deletePodRollbackGuidance: String {
        "No direct undo is available for pod deletion. If this pod is controller-managed, the controller should recreate it; otherwise recreate it manually from workload configuration."
    }

    @MainActor
    private var kubernetesActorLabel: String {
        selectedKubeContext.isEmpty ? "local-user" : "local-user@\(selectedKubeContext)"
    }

    @MainActor
    private func scaleRollbackGuidance(previousReplicas: String?) -> String {
        if let previousReplicas {
            return "To rollback, scale the deployment back to \(previousReplicas) replicas."
        }

        return "To rollback, scale the deployment back to the previously known replica count."
    }

    // MARK: - 사용자 로그

    func downloadUserLog(_ sno: String) async throws -> URL {
        try await userLogService.downloadUserLog(sno)
    }

    /// 선택 토글
    func toggleSelection(errorId: Int?) {
        guard let id = errorId else { return }
        if selectedErrors.contains(id) {
            selectedErrors.remove(id)
        } else {
            selectedErrors.insert(id)
        }
    }

    /// 모두 선택
    func selectAll() {
        selectedErrors = Set(errorItems.compactMap { $0.id })
    }

    /// 선택 해제
    func deselectAll() {
        selectedErrors.removeAll()
    }

    /// 선택된 개수
    var selectedCount: Int {
        selectedErrors.count
    }

    /// 일괄 삭제 가능 여부
    var canDeleteMultiple: Bool {
        !selectedErrors.isEmpty
    }
}
