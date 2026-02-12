import SwiftUI
import Logging


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

    let logger = Logger(label:"com.migmig.MobileAdmin.ViewModel")
    static var tokenExpirationDate: Date? // 토큰 만료 시간을 저장하는 변수
    static var token: String? // 토큰을 저장하는 변수
    static var currentServerType: EnvironmentType = EnvironmentConfig.current
    private static var tokenRefreshTask: Task<Void, Error>?

    // MARK: - 공유 DateFormatter (재생성 방지)
    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter
    }()

    private var baseUrl: String {
        return EnvironmentConfig.baseUrl
    }

    func setToken(token:String?){
        ViewModel.token = token
    }

    private func base64UrlDecode(_ input: String) -> Data? {
        var base64 = input.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")

        // Padding 처리
        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
        }

        return Data(base64Encoded: base64)
    }

    // JWT에서 유효 시간을 추출하는 함수
    private func extractExpiration(from token: String) -> Date? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            logger.warning("Invalid token format")
            return nil
        }

        guard let payloadData = base64UrlDecode(String(parts[1])) else {
            logger.warning("Failed to decode payload")
            return nil
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
               let exp = json["exp"] as? TimeInterval {
                return Date(timeIntervalSince1970: exp)
            }
        } catch {
            logger.error("Error decoding JWT payload: \(error)")
        }

        return nil
    }

    // MARK: - 토큰 관리

    /// 토큰 유효성 확인 및 필요시 갱신
    private func ensureValidToken() async throws {
        let needsRefresh = ViewModel.token == nil ||
            (ViewModel.tokenExpirationDate.map { $0 <= Date() } ?? true)

        guard needsRefresh else { return }

        // 이미 진행 중인 토큰 갱신이 있으면 대기
        if let existingTask = ViewModel.tokenRefreshTask {
            try await existingTask.value
            return
        }

        let task = Task {
            try await fetchToken()
            ViewModel.tokenRefreshTask = nil
        }
        ViewModel.tokenRefreshTask = task
        try await task.value
    }

    /// 인증된 URLRequest 생성
    private func makeAuthenticatedRequest(url urlString: String) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        if let token = ViewModel.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // 토큰을 가져오는 비동기 함수
    private func fetchToken() async throws {
        logger.info("fetchToken called")
        let url = "\(baseUrl)/simpleLoginForAdmin"
        guard let adminCI = Bundle.main.object(forInfoDictionaryKey: "adminCI") as? String else {
            throw NetworkError.missingCredential
        }

        let tokenRequestData = TokenRequest(ci: adminCI)
        guard let tokenUrl = URL(string: url) else {
            throw NetworkError.invalidURL(url)
        }
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(tokenRequestData)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: url)
        }
        guard let token = httpResponse.value(forHTTPHeaderField: "Authorization") else {
            throw NetworkError.missingToken
        }
        ViewModel.token = token
        ViewModel.tokenExpirationDate = extractExpiration(from: token)
    }

    // MARK: - 네트워크 요청 메서드

    // 모든 요청을 처리하는 비동기 함수
    private func makeRequestNoReturn<T: Codable>(
        url: String,
        requestData: T? = nil
    ) async throws  {
        try await ensureValidToken()
        var request = try makeAuthenticatedRequest(url: url)

        // 요청 데이터가 주어졌다면 JSON 인코딩
        if let requestData = requestData {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(Self.apiDateFormatter)
            request.httpBody = try encoder.encode(requestData)
        }

        let (_, _) = try await URLSession.shared.data(for: request)
    }

    // 파일처리를 제외한 요청을 처리하는 비동기 함수
    private func makeRequestNoRequestData<T: Codable>(
        url: String
    ) async throws -> T {
        try await ensureValidToken()
        let request = try makeAuthenticatedRequest(url: url)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: url)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.apiDateFormatter)
        let decodedData = try decoder.decode(T.self, from: data)

        return decodedData
    }

    // 모든 요청을 처리하는 비동기 함수
    private func makeRequest<R: Codable , T: Codable>(
        url: String,
        requestData: R? = nil
    ) async throws -> T {
        try await ensureValidToken()
        var request = try makeAuthenticatedRequest(url: url)

        // 요청 데이터가 주어졌다면 JSON 인코딩
        if let requestData = requestData {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(Self.apiDateFormatter)
            request.httpBody = try encoder.encode(requestData)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: url)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.apiDateFormatter)
        let decodedData = try decoder.decode(T.self, from: data)

        return decodedData
    }

    // MARK: - Toast API

    // Toast 데이터를 가져오는 비동기 함수
    func fetchToasts() async  -> Toast{
        do {
            let url = "\(baseUrl)/admin/toastNotice"
            let toast: Toast = try await makeRequestNoRequestData(url: url)
            return toast
        } catch {
            logger.error("fetchToasts 실패: \(error)")
        }
        return Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")
    }

    // Toast 노출 설정 함수
    func setNoticeVisible(toastData:Toast) async {
        do {
            let urlPath = "/admin/toastSetVisible/\(toastData.useYn)"
            try await makeRequestNoReturn(url: "\(baseUrl)\(urlPath)" , requestData: toastData)
        } catch {
            logger.error("setNoticeVisible 실패: \(error)")
        }
    }

    // Toast 데이터 설정 함수
    func setToastData(toastData:Toast) async {
        do {
            let urlPath = "/admin/toastSetNotice"
            try await makeRequestNoReturn(url: "\(baseUrl)\(urlPath)", requestData: toastData)
        } catch {
            logger.error("setToastData 실패: \(error)")
        }
    }

    // MARK: - Error Cloud API

    // Error 데이터를 가져오는 비동기 함수
    func fetchErrors(startFrom: Date, endTo: Date) async -> [ErrorCloudItem]?{
        do {
            let urlPath = "/admin/findByRegisterDtBetween/\(Util.getFormattedDateString(startFrom))/\(Util.getFormattedDateString(endTo))"
            let errorItems: [ErrorCloudItem] = try await makeRequestNoRequestData(url: "\(baseUrl)\(urlPath)")
            return errorItems
        } catch {
            logger.error("fetchErrors 실패: \(error)")
        }
        return nil
    }

    // Error 데이터 삭제 함수
    func deleteError(id:Int) async{
        do{
            let urlPath = "/admin/cloud/error/delete/\(id)"
            let _:[ErrorCloudItem] = try await makeRequestNoRequestData(url: "\(baseUrl)\(urlPath)")
        }catch {
            logger.error("deleteError 실패: \(error)")
        }
    }

    // MARK: - Goods API

    func fetchGoods(_ startFrom: Date?, _ endTo: Date?) async -> [Goodsinfo]?{
        do {
            let p_startFrom = Util.getCurrentDateString("yyyyMMdd", startFrom)
            let p_endTo     = Util.getCurrentDateString("yyyyMMdd", endTo)
            let urlPath     = "/admin/getGoodsHistList/\(p_startFrom)/\(p_endTo)"
            let goodsinfos: [Goodsinfo] = try await makeRequestNoRequestData(url: "\(baseUrl)\(urlPath)")
            return goodsinfos
        } catch {
            logger.error("fetchGoods 실패: \(error)")
        }
        return nil
    }

    // MARK: - 교육과정 API

    // 강의 리스트  데이터를 가져오는 비동기 함수
    func fetchClsLists() async  -> EdcCrseClListResponse{
        do {
            let url = "\(baseUrl)/gcamp/category/all-edu-list"
            let result: EdcCrseClListResponse? = try await makeRequestNoRequestData(url: url)
            return result ?? EdcCrseClListResponse()
        } catch {
            logger.error("fetchClsLists 실패: \(error)")
        }
        return EdcCrseClListResponse()
    }


    // 교육과정 데이터를 가져오는 비동기 함수
    func fetchClsInfo(edcCrseId:Int) async  -> EdcCrseResponse{
        do {
            let url = "\(baseUrl)/gcamp/category/education-crse-info"
            let resp:EdcCrseResponse? = try await makeRequest(
                url: url,
                requestData: EdcCrseClRequest(edcCrseId: edcCrseId)
            )
            return resp  ?? EdcCrseResponse()
        } catch {
            logger.error("fetchClsInfo 실패: \(error)")
        }
        return EdcCrseResponse()
    }

    // MARK: - 공통코드 API

    // 코드그룹 리스트  데이터를 가져오는 비동기 함수
    func fetchGroupCodeLists() async  -> [CmmnGroupCodeItem]{
        do {
            let url = "\(baseUrl)/admin/getCmmnGroupCodeList"
            let result: [CmmnGroupCodeItem]? = try await makeRequestNoRequestData(url: url)
            return result ?? []
        } catch {
            logger.error("fetchGroupCodeLists 실패: \(error)")
        }
        return []
    }


    // 코드 리스트  데이터를 가져오는 비동기 함수
    func fetchCodeListByGroupCode(_ groupCode:String) async  -> [CmmnCodeItem]{
        do {
            let url = "\(baseUrl)/admin/getCmmnCodeByCmmnGroupCode/\(groupCode)"
            let result: [CmmnCodeItem]? = try await makeRequestNoRequestData(url: url)
            return result ?? []
        } catch {
            logger.error("fetchCodeListByGroupCode 실패: \(error)")
        }
        return []
    }

    // MARK: - 개시마감 API

    func fetchCloseDeptList() async  -> CloseInfo {
        do {
            let url = "\(baseUrl)/admin/getStartEndOfDept"
            let result: CloseInfo? = try await makeRequestNoRequestData(url: url)

            return result ?? CloseInfo()
        } catch {
            logger.error("fetchCloseDeptList 실패: \(error)")
        }
        return CloseInfo()
    }

    // MARK: - Build API

    func fetchSourceBuildList() async -> BuildProjects {
        do{
            let url = "\(baseUrl)/admin/cloud/build-project-list"
            let result: BuildProjects? = try await makeRequestNoRequestData(url:url)
            return result ?? BuildProjects()
        }catch{
            logger.error("fetchSourceBuildList 실패: \(error)")
        }
        return BuildProjects()
    }

    func fetchSourceBuildInfo(_ buildId:Int) async -> SourceBuildInfo? {
        do{
            let url = "\(baseUrl)/admin/cloud/build-project-info/\(buildId)"
            let result: SourceBuildInfo? = try await makeRequestNoRequestData(url:url)
            return result
        }catch{
            logger.error("fetchSourceBuildInfo 실패: \(error)")
        }
        return nil
    }

    func execSourceBuild(_ buildId:Int) async -> BuildExecResult? {
        do{
            let url = "\(baseUrl)/admin/cloud/exec-build-project/\(buildId)"
            let result: BuildExecResult? = try await makeRequestNoRequestData(url:url)
            return result
        }catch{
            logger.error("execSourceBuild 실패: \(error)")
        }
        return nil
    }


    func fetchSourceBuildHistory(_ buildId:Int) async -> SourceBuildHistoryInfo? {
        do{
            let url = "\(baseUrl)/admin/cloud/build-project-history-info/\(buildId)"
            let result: SourceBuildHistoryInfo? = try await makeRequestNoRequestData(url:url)
            return result
        }catch{
            logger.error("fetchSourceBuildHistory 실패: \(error)")
        }
        return nil
    }

    // MARK: - Pipeline API

    func fetchSourcePipelineList() async -> SourceProjectInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/pipeline-project-list"
            let result: SourceProjectInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceProjectInfo()
        }catch{
            logger.error("fetchSourcePipelineList 실패: \(error)")
        }
        return SourceProjectInfo()
    }

    //SourcePipelineHistoryInfo
    func fetchSourcePipelineHistoryInfo(_ projectId:Int) async -> SourcePipelineHistoryInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/pipeline-history-info/\(projectId)"
            let result: SourcePipelineHistoryInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourcePipelineHistoryInfo()
        }catch{
            logger.error("fetchSourcePipelineHistoryInfo 실패: \(error)")
        }
        return SourcePipelineHistoryInfo()
    }

    func runSourcePipeline(_ projectId:Int) async -> SourcePipelineExecResult {
        do{
            let url = "\(baseUrl)/admin/cloud/exec-pipeline-project/\(projectId)"
            let result: SourcePipelineExecResult? = try await makeRequestNoRequestData(url:url)
            return result ?? SourcePipelineExecResult()
        }catch{
            logger.error("runSourcePipeline 실패: \(error)")
        }
        return SourcePipelineExecResult()
    }

    func cancelSourcePipeline(_ projectId:Int, _ historyId:Int) async -> SourcePipelineExecResult {
        do{
            let url = "\(baseUrl)/admin/cloud/cancel-pipeline-project/\(projectId)/\(historyId)"
            let result: SourcePipelineExecResult? = try await makeRequestNoRequestData(url:url)
            return result ?? SourcePipelineExecResult()
        }catch{
            logger.error("cancelSourcePipeline 실패: \(error)")
        }
        return SourcePipelineExecResult()
    }

    // MARK: - Commit API

    //commit-repository-list
    func fetchSourceCommitList() async -> SourceCommitInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/commit-repository-list"
            let result: SourceCommitInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceCommitInfo()
        }catch{
            logger.error("fetchSourceCommitList 실패: \(error)")
        }
        return SourceCommitInfo()
    }

    //commit-repository-branch-list
    func fetchSourceCommitBranchList(_ repositoryName:String) async -> SourceCommitBranchInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/commit-repository-branch-list/\(repositoryName)"
            let result: SourceCommitBranchInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceCommitBranchInfo()
        }catch{
            logger.error("fetchSourceCommitBranchList 실패: \(error)")
        }
        return SourceCommitBranchInfo()
    }

    // MARK: - Deploy API

    func fetchSourceDeployList() async -> SourceProjectInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/deploy-project-list"
            let result: SourceProjectInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceProjectInfo()
        }catch{
            logger.error("fetchSourceDeployList 실패: \(error)")
        }
        return SourceProjectInfo()
    }


    func fetchSourceDeployHistoryInfo(_ projectId:Int) async -> SourceDeployHistoryInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/deploy-project-history-list/\(projectId)"
            let result: SourceDeployHistoryInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceDeployHistoryInfo()
        }catch{
            logger.error("fetchSourceDeployHistoryInfo 실패: \(error)")
        }
        return SourceDeployHistoryInfo()
    }


   func fetchSourceDeployStageInfo(_ projectId:Int) async -> SourceDeployStageInfo {
       do{
           let url = "\(baseUrl)/admin/cloud/deploy-project-stage/\(projectId)"
           let result: SourceDeployStageInfo? = try await makeRequestNoRequestData(url:url)
           return result ?? SourceDeployStageInfo()
       }catch{
           logger.error("fetchSourceDeployStageInfo 실패: \(error)")
       }
       return SourceDeployStageInfo()
   }

    //deploy-project-scenario
    func fetchSourceDeployScenarioInfo(_ projectId:Int,_ stageId:Int) async -> SourceDeployScenarioInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/deploy-project-scenario/\(projectId)/\(stageId)"
            let result: SourceDeployScenarioInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceDeployScenarioInfo()
        }catch{
            logger.error("fetchSourceDeployScenarioInfo 실패: \(error)")
        }
        return SourceDeployScenarioInfo()
    }

    func runSourceDeploy(_ projectId:Int,_ stageId:Int,_ scenarioId:Int) async -> SourceDeployExecResult {
        do{
            let url = "\(baseUrl)/admin/cloud/exec-deploy/\(projectId)/\(stageId)/\(scenarioId)"
            let result: SourceDeployExecResult? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceDeployExecResult()
        }catch{
            logger.error("runSourceDeploy 실패: \(error)")
        }
        return SourceDeployExecResult()
    }

    // MARK: - 사용자 로그

    // UT번호에서 앞의 "UT" 제거 + 숫자만 남기는 유틸
    private func normalizeUserLogNo(_ sno: String) -> String {
        if sno.hasPrefix("UT") {
            let index = sno.index(sno.startIndex, offsetBy: 2)
            return String(sno[index...])   // "UT00000000001" -> "00000000001"
        } else {
            return sno
        }
    }

    // 번호를 UT + 11자리로 패딩해서 파일명 만드는 유틸
    private func makeUserLogFileName(no: String) -> String {
        // 숫자만 추출
        let digits = no.filter { $0.isNumber }
        let padded = String(repeating: "0", count: max(0, 11 - digits.count)) + digits
        return "UT\(padded).log"
    }

    /// 사용자 로그를 다운로드해서 파일 URL을 반환
    /// - Parameter sno: "0", "123", "UT00000000123" 어떤 형식이든 가능
    /// - Returns: 저장된 파일의 URL
    func downloadUserLog(_ sno: String) async throws -> URL {
        // 1) 토큰 유효성 체크
        try await ensureValidToken()

        // 2) 번호 정규화
        let no = normalizeUserLogNo(sno)
        let urlString = "\(baseUrl)/admin/getUserLog/\(no)"

        // 3) 요청 구성
        var request = try makeAuthenticatedRequest(url: urlString)
        request.httpMethod = "POST"

        // 4) 요청 전송
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: urlString)
        }

        // 5) 파일 저장 경로
        #if os(macOS)
        let directory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        #else
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #endif

        guard let saveDir = directory else {
            throw NetworkError.noData
        }

        let fileName = makeUserLogFileName(no: no)
        let fileURL = saveDir.appendingPathComponent(fileName)

        // 6) 파일 저장
        try data.write(to: fileURL, options: .atomic)

        logger.info("User log downloaded: \(fileURL.path)")

        return fileURL
    }
}
