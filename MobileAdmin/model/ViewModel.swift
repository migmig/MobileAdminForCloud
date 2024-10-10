
import SwiftUI

struct token: Codable{
    var ci: String
}


class ViewModel: ObservableObject{
    @Published var toasts:Toast = Toast()
    @Published var errorItems:[ErrorCloudItem] = []
    @AppStorage("baseUrl") var baseUrl = "https://untact.gcgf.or.kr:3002"
//    @AppStorage("baseUrl") var baseUrl = "http://172.16.111.7:8080"
    
    private static func today(minus days: Int) -> Date {
        let dateComponents = DateComponents(day: -days)
        return Calendar.current.date(byAdding: dateComponents, to: Date()) ?? Date()
    }
    
    func getToken(completion:@escaping(String?) -> Void){
        
        guard let url = URL(string:"\(baseUrl)/simpleLoginForAdmin") else{return}
        
        let newToken = token(ci: "QQi4nORX5GzJXq2YWfre9HpW8UkAd0F4AuxQsd2a/hb1JSRnfzk+b+vqTKjQhcVOZNXCLaIQyNF6yKxihjrQlw==")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*",forHTTPHeaderField: "Accept")
        
        guard let httpBody = try? JSONEncoder().encode(newToken) else{return}
        request.httpBody = httpBody
         
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("error: \(error)")
                    completion(nil)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("fail response")
                    completion(nil)
                    return
                }
                if let token = httpResponse.value(forHTTPHeaderField: "Authorization") {
                    completion(token)
                } else {
                    print("Authorization header is missing")
                    completion(nil)
                }
            }
        }.resume()
        
        
    }
    
    func fetchToasts(completion:@escaping(Toast?) -> Void){
        var sTokenString:String?
        getToken{sToken in
            if let sToken {
               // print("getToken: \(sToken)")
                sTokenString = sToken;
                
                guard let url = URL(string:"\(self.baseUrl)/admin/toastNotice") else{return}
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                request.setValue("application/json", forHTTPHeaderField: "Content-type")
                request.setValue("*/*",forHTTPHeaderField: "Accept")
                request.setValue("Bearer \(sTokenString!)", forHTTPHeaderField: "Authorization")
                 
                 
                URLSession.shared.dataTask(with: request){data,response,error in
                    DispatchQueue.main.async{
                        if let httpResponse = response as? HTTPURLResponse {
                            print("HTTP 응답 코드: \(httpResponse.statusCode)")
                        }
                        guard let data else{return}
                        
                        //                    let jsonString = String(data: data, encoding: .utf8)
                        // print("jsonString: \(jsonString ?? "nil")")
                        do{
                            let decoder = JSONDecoder()
                            let toast = try decoder.decode(Toast.self, from: data)
                            self.toasts = toast
                            completion(toast)
                        }catch{
                            print("error: \(error)")
                            completion(nil)
                        }
                    }
                }.resume()
            }else{
                print("get Token failed")
            }
        }
    }
    
    func fetchErrors(completion:@escaping([ErrorCloudItem]?) -> Void
                     ,startFrom:String
                     ,endTo:String){
        var sTokenString:String?
        getToken{sToken in
            if let sToken {
               // print("getToken: \(sToken)")
                sTokenString = sToken;
                
                guard let url = URL(string:"\(self.baseUrl)/admin/findByRegisterDtBetween/\(startFrom)/\(endTo)") else{return}
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                request.setValue("application/json", forHTTPHeaderField: "Content-type")
                request.setValue("*/*",forHTTPHeaderField: "Accept")
                request.setValue("Bearer \(sTokenString!)", forHTTPHeaderField: "Authorization")
                 
                
                URLSession.shared.dataTask(with: request){data,response,error in
                    DispatchQueue.main.async{
                        if let httpResponse = response as? HTTPURLResponse {
                            print("HTTP 응답 코드: \(httpResponse.statusCode)")
                        }
                        guard let data else{return}
                        
                        //                    let jsonString = String(data: data, encoding: .utf8)
                        // print("jsonString: \(jsonString ?? "nil")")
                        do{
                            let decoder = JSONDecoder()
                            let errorItems = try decoder.decode([ErrorCloudItem].self, from: data)
                            self.errorItems = errorItems
                            completion(errorItems)
                        }catch{
                            print("error: \(error)")
                            completion(nil)
                        }
                    }
                }.resume()
            }else{
                print("get Token failed")
            }
        }
    }
}
