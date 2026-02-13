import SwiftUI
import Logging

/// ViewModel facade - 뷰에서 @EnvironmentObject로 접근하는 진입점
/// 실제 비즈니스 로직은 도메인별 서비스로 위임
class ViewModel: ObservableObject {
    @Published var buildProjects : [SourceBuildProject] = []
    @Published var errorItems    : [ErrorCloudItem] = []
    @Published var goodsItems    : [Goodsinfo] = []
    @Published var edcCrseCllist : [EdcCrseCl] = []
    @Published var sourceCommitInfoRepository : [SourceCommitInfoRepository] = []
    @Published var sourcePipelineList : [SourceInfoProjectInfo] = []
    @Published var sourcePipelineHistoryList: [SourcePipelineHistoryInfoHistoryList] = []
    @Published var sourceDeployList : [SourceInfoProjectInfo] = []
    @Published var sourceDeployHistoryList : [SourceDeployHistoryInfoHistoryList] = []
    @Published var lastError: NetworkError?

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

    private let networkClient = NetworkClient()
    private lazy var toastService = ToastService(client: networkClient)
    private lazy var errorService = ErrorService(client: networkClient)
    private lazy var goodsService = GoodsService(client: networkClient)
    private lazy var educationService = EducationService(client: networkClient)
    private lazy var codeService = CodeService(client: networkClient)
    private lazy var closeDeptService = CloseDeptService(client: networkClient)
    private lazy var buildService = BuildService(client: networkClient)
    private lazy var pipelineService = PipelineService(client: networkClient)
    private lazy var commitService = CommitService(client: networkClient)
    private lazy var deployService = DeployService(client: networkClient)
    private lazy var userLogService = UserLogService(client: networkClient)

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

    // MARK: - 사용자 로그

    func downloadUserLog(_ sno: String) async throws -> URL {
        try await userLogService.downloadUserLog(sno)
    }
}
