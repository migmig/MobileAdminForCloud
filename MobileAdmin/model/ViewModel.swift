import SwiftUI
import Logging


class ViewModel: ObservableObject {
    //    @Published var toasts: Toast = Toast()
    //    @Published var errorItems: [ErrorCloudItem] = []

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
        //        logger.info("fetchToken called")
        let url = "\(baseUrl)/simpleLoginForAdmin"
        let adminCI:String  = Bundle.main.object(forInfoDictionaryKey: "adminCI") as! String


        let tokenRequestData = TokenRequest(ci: adminCI)

        var request = URLRequest(url: URL(string: url)!)
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

    // 모든 요청을 처리하는 비동기 함수
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
      

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Invalid Response", code: 0, userInfo: nil)
        }

//        let stringfromdata = String(data: data, encoding: .utf8)
//        print("data:\(String(describing: String(data: data, encoding: .utf8)))")
        
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

        let stringfromdata = String(data: data, encoding: .utf8)
        print("data:\(String(describing: String(data: data, encoding: .utf8)))")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        let decodedData = try decoder.decode(T.self, from: data)
        
        return decodedData
    }

    // Toast 데이터를 가져오는 비동기 함수
    func fetchToasts() async  -> Toast{
        do {
            let url = "\(baseUrl)/admin/toastNotice"
            let toast: Toast? = try await makeRequestNoRequestData(url: url)
            return toast ?? Toast(applcBeginDt: Date(), applcEndDt: Date(), noticeHder: "", noticeSj: "", noticeCn: "", useYn: "N")
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
}
