import SwiftUI
import Logging
 

class ViewModel: ObservableObject {
//    @Published var toasts: Toast = Toast()
//    @Published var errorItems: [ErrorCloudItem] = []
    
    let logger = Logger(label:"com.migmig.MobileAdmin.ViewModel")
    static var tokenExpirationDate: Date? // 토큰 만료 시간을 저장하는 변수
    static var token: String? // 토큰 만료 시간을 저장하는 변수
    
    private var baseUrl: String {
        return EnvironmentConfig.baseUrl
    }
    
    private static func today(minus days: Int) -> Date {
        let dateComponents = DateComponents(day: -days)
        return Calendar.current.date(byAdding: dateComponents, to: Date()) ?? Date()
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
        let tokenRequestData = TokenRequest(ci: "QQi4nORX5GzJXq2YWfre9HpW8UkAd0F4AuxQsd2a/hb1JSRnfzk+b+vqTKjQhcVOZNXCLaIQyNF6yKxihjrQlw==")
        
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

        // 요청 데이터가 주어졌다면 JSON 인코딩
        if let requestData = requestData {
            request.httpBody = try JSONEncoder().encode(requestData)
        }

        let (_, _) = try await URLSession.shared.data(for: request)
         
    }
    
    // 모든 요청을 처리하는 비동기 함수
    private func makeRequest<T: Codable>(
        url: String,
        requestData: T? = nil
    ) async throws -> T {
//        logger.info("makeRequest called with url: \(url) and token: \(ViewModel.token ?? "none") ")
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

        // 요청 데이터가 주어졌다면 JSON 인코딩
        if let requestData = requestData {
            request.httpBody = try JSONEncoder().encode(requestData)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Invalid Response", code: 0, userInfo: nil)
        }

        let decodedData = try JSONDecoder().decode(T.self, from: data)
        return decodedData
    }

    // Toast 데이터를 가져오는 비동기 함수
    func fetchToasts() async  -> Toast?{
        do {
            let url = "\(baseUrl)/admin/toastNotice"
            let toast: Toast = try await makeRequest(url: url)
            return toast
        } catch {
            print("Error fetching toasts: \(error)")
        }
        return nil
    }

    // Error 데이터를 가져오는 비동기 함수
    func fetchErrors(startFrom: String, endTo: String) async -> [ErrorCloudItem]?{
        do {
//            logger.info("fetchErrors called")
            let urlPath = "/admin/findByRegisterDtBetween/\(startFrom)/\(endTo)"
            let errorItems: [ErrorCloudItem] = try await makeRequest(url: "\(baseUrl)\(urlPath)")
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
}
