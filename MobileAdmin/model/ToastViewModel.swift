
import SwiftUI

struct token: Codable{
    var ci: String
}


class ToastViewModel: ObservableObject{
    @Published var toasts:Toast = Toast()
    
    func getToken(completion:@escaping(String?) -> Void){
        
        guard let url = URL(string:"http://172.16.111.7:8080/simpleLoginForAdmin") else{return}
        
        let newToken = token(ci: "QQi4nORX5GzJXq2YWfre9HpW8UkAd0F4AuxQsd2a/hb1JSRnfzk+b+vqTKjQhcVOZNXCLaIQyNF6yKxihjrQlw==")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("*/*",forHTTPHeaderField: "Accept")
        
        guard let httpBody = try? JSONEncoder().encode(newToken) else{return}
        request.httpBody = httpBody
         
        
        URLSession.shared.dataTask(with: request){data,response,error in
            if let error = error{
                print("error: \(error)")
                completion(nil)
            }
            print("\(data.debugDescription)")
            if let httpResponse = response as? HTTPURLResponse{
                if let aToken = httpResponse.value(forHTTPHeaderField: "Authorization"){
                    completion(aToken)
                }else{
                    print("Authorization header is missing")
                    completion(nil)
                }
            }else{
                print("fail response")
                completion(nil)
            }
        }.resume()
        
        
    }
    
    func fetchToasts(completion:@escaping(Toast?) -> Void){
        var sTokenString:String?
        getToken{sToken in
            if let sToken {
               // print("getToken: \(sToken)")
                sTokenString = sToken;
                
                guard let url = URL(string:"http://172.16.111.7:8080/admin/toastNotice") else{return}
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                request.setValue("application/json", forHTTPHeaderField: "Content-type")
                request.setValue("*/*",forHTTPHeaderField: "Accept")
                request.setValue("Bearer \(sTokenString!)", forHTTPHeaderField: "Authorization")
                 
                
                URLSession.shared.dataTask(with: request){data,response,error in
                    if let httpResponse = response as? HTTPURLResponse {
                        print("HTTP 응답 코드: \(httpResponse.statusCode)")
                    }
                    guard let data else{return}
                     
                    let jsonString = String(data: data, encoding: .utf8)
                   // print("jsonString: \(jsonString ?? "nil")")
                    do{
                        let decoder = JSONDecoder()
                        let toast = try decoder.decode(Toast.self, from: data)
                        DispatchQueue.main.async{
                            self.toasts = toast
                            completion(toast)
                        }
                    }catch{
                        print("error: \(error)")
                        completion(nil)
                    }
                }.resume()
            }else{
                print("get Token failed")
            }
        }
    }
}
