import SwiftUI
 
 

class ViewModel: ObservableObject {
    @Published var toasts: Toast = Toast()
    @Published var errorItems: [ErrorCloudItem] = []
    
    private var baseUrl: String {
        return EnvironmentConfig.baseUrl
    }
    
    private static func today(minus days: Int) -> Date {
        let dateComponents = DateComponents(day: -days)
        return Calendar.current.date(byAdding: dateComponents, to: Date()) ?? Date()
    }

    // 토큰을 가져오는 비동기 함수
    private func fetchToken() async throws -> String {
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
        
        if let token = httpResponse.value(forHTTPHeaderField: "Authorization") {
            return token
        } else {
            throw NSError(domain: "Authorization header is missing", code: 0, userInfo: nil)
        }
    }

    // 모든 요청을 처리하는 비동기 함수
    private func makeRequest<T: Codable>(
        url: String,
        requestData: T? = nil,
        token : String?
    ) async throws -> T {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        if(token != nil){
            request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
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
            let token = try await fetchToken()
            let url = "\(baseUrl)/admin/toastNotice"
            let toast: Toast = try await makeRequest(url: url,token: token)
            return toast
        } catch {
            print("Error fetching toasts: \(error)")
        }
        return nil
    }

    // Error 데이터를 가져오는 비동기 함수
    func fetchErrors(startFrom: String, endTo: String) async -> [ErrorCloudItem]?{
        do {
            let token  = try await fetchToken()
            let urlPath = "/admin/findByRegisterDtBetween/\(startFrom)/\(endTo)"
            let errorItems: [ErrorCloudItem] = try await makeRequest(url: "\(baseUrl)\(urlPath)", token:token)
            return errorItems
        } catch {
            print("Error fetching errors: \(error)")
        }
        return nil
    }
}
