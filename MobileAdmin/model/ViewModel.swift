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

    let logger = Logger(label:"com.migmig.MobileAdmin.ViewModel")
    static var tokenExpirationDate: Date? // 토큰 만료 시간을 저장하는 변수
    static var token: String? // 토큰 만료 시간을 저장하는 변수
    static var currentServerType: EnvironmentType = EnvironmentConfig.current

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
            print("Invalid token format")
            return nil
        }

        guard let payloadData = base64UrlDecode(String(parts[1])) else {
            print("Failed to decode payload")
            return nil
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
               let exp = json["exp"] as? TimeInterval {
                return Date(timeIntervalSince1970: exp)
            }
        } catch {
            print("Error decoding JWT payload: \(error)")
        }

        return nil
    }

    // 토큰을 가져오는 비동기 함수
    private func fetchToken() async throws {
        logger.info("fetchToken called")
        let url = "\(baseUrl)/simpleLoginForAdmin"
        let adminCI:String  = Bundle.main.object(forInfoDictionaryKey: "adminCI") as! String


        let tokenRequestData = TokenRequest(ci: adminCI)
        let tokenUrl =  URL(string: url)
        if tokenUrl == nil {
            throw NSError(domain: "Invalid token url", code: 0, userInfo: nil)
        }
        var request = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(tokenRequestData)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Invalid Response", code: 0, userInfo: nil)
        }
        ViewModel.token = httpResponse.value(forHTTPHeaderField: "Authorization")
        //        logger.info("get token sucess:\(ViewModel.token!)")
        if ViewModel.token != nil {
            ViewModel.tokenExpirationDate = extractExpiration(from: ViewModel.token!)
        } else {
            throw NSError(domain: "Authorization header is missing", code: 0, userInfo: nil)
        }
    }

    // 모든 요청을 처리하는 비동기 함수
    private func makeRequestNoReturn<T: Codable>(
        url: String,
        requestData: T? = nil
    ) async throws  {
        if ViewModel.token == nil{
            try await fetchToken()
        }else{
            if let expirationDate = ViewModel.tokenExpirationDate, expirationDate <= Date() {
                try await fetchToken()
            }
        }
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        if(ViewModel.token != nil){
            request.setValue("Bearer \(ViewModel.token!)", forHTTPHeaderField: "Authorization")
        }

        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        // 요청 데이터가 주어졌다면 JSON 인코딩
        if let requestData = requestData {
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            let str = try encoder.encode(requestData)
           // print(str)
            request.httpBody = str
        }

        let (_, _) = try await URLSession.shared.data(for: request)

    }

    // 파일처리를 제외한 요청을 처리하는 비동기 함수
    private func makeRequestNoRequestData<T: Codable>(
        url: String
    ) async throws -> T {
        //        logger.info("makeRequest called with url: \(url) and token: \(ViewModel.token ?? "none") ")
        if ViewModel.token == nil{
            try await fetchToken()
        }else{
            if let expirationDate = ViewModel.tokenExpirationDate, expirationDate <= Date() {
                try await fetchToken()
            }
        }
        //print(url);
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        if(ViewModel.token != nil){
            request.setValue("Bearer \(ViewModel.token!)", forHTTPHeaderField: "Authorization")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
      

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Invalid Response", code: 0, userInfo: nil)
        }

       // let stringfromdata = String(data: data, encoding: .utf8)
       // print("data:\(String(describing: String(data: data, encoding: .utf8)))")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        let decodedData = try decoder.decode(T.self, from: data)
        
        return decodedData
    }
    // 모든 요청을 처리하는 비동기 함수
    private func makeRequest<R: Codable , T: Codable>(
        url: String,
        requestData: R? = nil
    ) async throws -> T {
        //        logger.info("makeRequest called with url: \(url) and token: \(ViewModel.token ?? "none") ")
        if ViewModel.token == nil{
            try await fetchToken()
        }else{
            if let expirationDate = ViewModel.tokenExpirationDate, expirationDate <= Date() {
                try await fetchToken()
            }
        }
        print(url);
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        if(ViewModel.token != nil){
            request.setValue("Bearer \(ViewModel.token!)", forHTTPHeaderField: "Authorization")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        // 요청 데이터가 주어졌다면 JSON 인코딩
        if let requestData = requestData {
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            let str = try encoder.encode(requestData)
            //print(str)
            request.httpBody = str
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Invalid Response", code: 0, userInfo: nil)
        }

      //  let stringfromdata = String(data: data, encoding: .utf8)
       // print("data:\(String(describing: String(data: data, encoding: .utf8)))")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        let decodedData = try decoder.decode(T.self, from: data)
        
        return decodedData
    }

    // Toast 데이터를 가져오는 비동기 함수
    func fetchToasts() async  -> Toast{
        do {
            let url = "\(baseUrl)/admin/toastNotice"
            //let toast: Toast? = nil//try await makeRequestNoRequestData(url: url)
            return Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")
        } catch {
            print("Error fetching toasts: \(error)")
        }
        return Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")
    }

    // Error 데이터를 가져오는 비동기 함수
    func fetchErrors(startFrom: Date, endTo: Date) async -> [ErrorCloudItem]?{
        do {
            let urlPath = "/admin/findByRegisterDtBetween/\(Util.getFormattedDateString(startFrom))/\(Util.getFormattedDateString(endTo))"
            let errorItems: [ErrorCloudItem] = try await makeRequestNoRequestData(url: "\(baseUrl)\(urlPath)")
            return errorItems
        } catch {
            print("Error fetching errors: \(error)")
        }
        return nil
    }
    
    // Error 데이터 삭제 함수
    func deleteError(id:Int) async{
        do{
            let urlPath = "/admin/cloud/error/delete/\(id)"
            print(urlPath)
            let errorItems:[ErrorCloudItem] = try await makeRequestNoRequestData(url: "\(baseUrl)\(urlPath)")
        }catch {
            print("Error fetching errors: \(error)")
        }
    }

    // Error 데이터를 가져오는 비동기 함수
    func setNoticeVisible(toastData:Toast) async {
        do {
            let urlPath = "/admin/toastSetVisible/\(toastData.useYn)"
            try await makeRequestNoReturn(url: "\(baseUrl)\(urlPath)" , requestData: toastData)
        } catch {
            print("Error fetching errors: \(error)")
        }
    }

    // Error 데이터를 가져오는 비동기 함수
    func setToastData(toastData:Toast) async {
        do {
            let urlPath = "/admin/toastSetNotice"
            try await makeRequestNoReturn(url: "\(baseUrl)\(urlPath)", requestData: toastData)
        } catch {
            print("Error fetching errors: \(error)")
        }
    }

    func fetchGoods(_ startFrom: Date?, _ endTo: Date?) async -> [Goodsinfo]?{
        do {
            let p_startFrom = Util.getCurrentDateString("yyyyMMdd", startFrom)
            let p_endTo     = Util.getCurrentDateString("yyyyMMdd", endTo)
            let urlPath     = "/admin/getGoodsHistList/\(p_startFrom)/\(p_endTo)"
            let goodsinfos: [Goodsinfo] = try await makeRequestNoRequestData(url: "\(baseUrl)\(urlPath)")
            return goodsinfos
        } catch {
            print("Error fetching errors: \(error)")
        }
        return nil
    }
    
    
    // 강의 리스트  데이터를 가져오는 비동기 함수
    func fetchClsLists() async  -> EdcCrseClListResponse{
        do {
            let url = "\(baseUrl)/gcamp/category/all-edu-list"
            let toast: EdcCrseClListResponse? = try await makeRequestNoRequestData(url: url)
            return toast ?? EdcCrseClListResponse()
        } catch {
            print("Error fetching toasts: \(error)")
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
            print("Error fetching EdcCrseResponse: \(error)")
        }
        return EdcCrseResponse()
    }
    
    
    // 코드그룹 리스트  데이터를 가져오는 비동기 함수
    func fetchGroupCodeLists() async  -> [CmmnGroupCodeItem]{
        do {
            let url = "\(baseUrl)/admin/getCmmnGroupCodeList"
            let result: [CmmnGroupCodeItem]? = try await makeRequestNoRequestData(url: url)
            return result ?? []
        } catch {
            print("Error fetching toasts: \(error)")
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
            print("Error fetching toasts: \(error)")
        }
        return []
    }
    
    func fetchCloseDeptList() async  -> CloseInfo {
        do {
            let url = "\(baseUrl)/admin/getStartEndOfDept"
            let result: CloseInfo? = try await makeRequestNoRequestData(url: url)
            
            return result ?? CloseInfo()
        } catch {
            print("Error fetching deptlist: \(error)")
        }
        return CloseInfo()
    }
    
    func fetchSourceBuildList() async -> BuildProjects {
        do{
            let url = "\(baseUrl)/admin/cloud/build-project-list"
            let result: BuildProjects? = try await makeRequestNoRequestData(url:url)
            return result ?? BuildProjects()
        }catch{
            print("Error fetchSourceBuildList: \(error)")
        }
        return BuildProjects()
    }
    
    func fetchSourceBuildInfo(_ buildId:Int) async -> SourceBuildInfo? {
        do{
            let url = "\(baseUrl)/admin/cloud/build-project-info/\(buildId)"
            let result: SourceBuildInfo? = try await makeRequestNoRequestData(url:url)
            return result
        }catch{
            print("Error fetchSourceBuildInfo: \(error)")
        }
        return nil
    }
    
    func execSourceBuild(_ buildId:Int) async -> BuildExecResult? {
        do{
            let url = "\(baseUrl)/admin/cloud/exec-build-project/\(buildId)"
            let result: BuildExecResult? = try await makeRequestNoRequestData(url:url)
            return result
        }catch{
            print("Error execSourceBuild: \(error)")
        }
        return nil
    }
    
    
    func fetchSourceBuildHistory(_ buildId:Int) async -> SourceBuildHistoryInfo? {
        do{
            let url = "\(baseUrl)/admin/cloud/build-project-history-info/\(buildId)"
            let result: SourceBuildHistoryInfo? = try await makeRequestNoRequestData(url:url)
            return result
        }catch{
            print("Error fetchSourceBuildHistory: \(error)")
        }
        return nil
    }
    
    func fetchSourcePipelineList() async -> SourceProjectInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/pipeline-project-list"
            let result: SourceProjectInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceProjectInfo()
        }catch{
            print("Error fetchSourcePipelineList: \(error)")
        }
        return SourceProjectInfo()
    }
    
    //commit-repository-list
    func fetchSourceCommitList() async -> SourceCommitInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/commit-repository-list"
            let result: SourceCommitInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceCommitInfo()
        }catch{
            print("Error fetchSourceCommitList: \(error)")
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
            print("Error fetchSourceCommitList: \(error)")
        }
        return SourceCommitBranchInfo()
    }
    
    //SourcePipelineHistoryInfo
    func fetchSourcePipelineHistoryInfo(_ projectId:Int) async -> SourcePipelineHistoryInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/pipeline-history-info/\(projectId)"
            let result: SourcePipelineHistoryInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourcePipelineHistoryInfo()
        }catch{
            print("Error fetchSourcePipelineHistoryInfo: \(error)")
        }
        return SourcePipelineHistoryInfo()
    }
    func runSourcePipeline(_ projectId:Int) async -> SourcePipelineExecResult {
        do{
            let url = "\(baseUrl)/admin/cloud/exec-pipeline-project/\(projectId)"
            let result: SourcePipelineExecResult? = try await makeRequestNoRequestData(url:url)
            return result ?? SourcePipelineExecResult()
        }catch{
            print("Error runSourcePipeline: \(error)")
        }
        return SourcePipelineExecResult()
    }
    
    func cancelSourcePipeline(_ projectId:Int, _ historyId:Int) async -> SourcePipelineExecResult {
        do{
            let url = "\(baseUrl)/admin/cloud/cancel-pipeline-project/\(projectId)/\(historyId)"
            let result: SourcePipelineExecResult? = try await makeRequestNoRequestData(url:url)
            return result ?? SourcePipelineExecResult()
        }catch{
            print("Error cancelSourcePipeline: \(error)")
        }
        return SourcePipelineExecResult()
    }
    
    
    func fetchSourceDeployList() async -> SourceProjectInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/deploy-project-list"
            let result: SourceProjectInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceProjectInfo()
        }catch{
            print("Error fetchSourceDeployList: \(error)")
        }
        return SourceProjectInfo()
    }
    
     
    func fetchSourceDeployHistoryInfo(_ projectId:Int) async -> SourceDeployHistoryInfo {
        do{
            let url = "\(baseUrl)/admin/cloud/deploy-project-history-list/\(projectId)"
            let result: SourceDeployHistoryInfo? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceDeployHistoryInfo()
        }catch{
            print("Error fetchSourceDeployHistoryInfo: \(error)")
        }
        return SourceDeployHistoryInfo()
    }
    
    
   func fetchSourceDeployStageInfo(_ projectId:Int) async -> SourceDeployStageInfo {
       do{
           let url = "\(baseUrl)/admin/cloud/deploy-project-stage/\(projectId)"
           let result: SourceDeployStageInfo? = try await makeRequestNoRequestData(url:url)
           return result ?? SourceDeployStageInfo()
       }catch{
           print("Error fetchSourceDeployStageInfo: \(error)")
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
            print("Error fetchSourceDeployScenarioInfo: \(error)")
        }
        return SourceDeployScenarioInfo()
    }

    func runSourceDeploy(_ projectId:Int,_ stageId:Int,_ scenarioId:Int) async -> SourceDeployExecResult {
        do{
            let url = "\(baseUrl)/admin/cloud/exec-deploy/\(projectId)/\(stageId)/\(scenarioId)"
            let result: SourceDeployExecResult? = try await makeRequestNoRequestData(url:url)
            return result ?? SourceDeployExecResult()
        }catch{
            print("Error runSourceDeploy: \(error)")
        }
        return SourceDeployExecResult()
    }
    
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
        if ViewModel.token == nil {
            try await fetchToken()
        } else if let expirationDate = ViewModel.tokenExpirationDate,
                  expirationDate <= Date() {
            try await fetchToken()
        }

        // 2) 번호 정규화
        let no = normalizeUserLogNo(sno)
        let urlString = "\(baseUrl)/admin/getUserLog/\(no)"

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }

        // 3) 요청 구성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        if let token = ViewModel.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 4) 요청 전송
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Invalid Response", code: 0, userInfo: [
                "statusCode": (response as? HTTPURLResponse)?.statusCode ?? -1
            ])
        }

        // 5) 파일 저장 경로 (macOS면 .downloadsDirectory, iOS면 .documentDirectory 같은 거 골라서)
        #if os(macOS)
        let directory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        #else
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #endif

        guard let saveDir = directory else {
            throw NSError(domain: "Directory not found", code: 0, userInfo: nil)
        }

        let fileName = makeUserLogFileName(no: no)
        let fileURL = saveDir.appendingPathComponent(fileName)

        // 6) 파일 저장
        try data.write(to: fileURL, options: .atomic)

        logger.info("User log downloaded: \(fileURL.path)")

        return fileURL
    }
}
