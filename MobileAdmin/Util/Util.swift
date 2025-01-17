//
//  Util.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/10/24.
//

import Foundation
import SwiftUI

class Util{
    
    static func urlEncode(_ string: String?) -> String {
        guard let string = string else {
            return ""
        }
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    static func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
    // 날짜 형식 변환 함수
    static func formattedDate(_ dateString: String) -> String {
        return  dateString.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "")
    }
    static func formatDateTime(_ dateString: String?) -> String {
        guard let dateString = dateString else{
            return ""
        }
        let isoformatter = DateFormatter()
        isoformatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS" // ISO8601 형식
        guard let date = isoformatter.date(from:dateString) else{
            return ""
        }
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy-MM-dd HH:mm:ss" // 날짜 형식을 설정
        return formatter2.string(from: date) // 포맷된 문자열 반환
    }
    

   // JSON 또는 HashMap toString() 포매팅 함수 (userEncMsg 제외, 잘린 JSON 처리)
    static func formatRequestInfo(_ requestInfo: String) -> String {
       // JSON 포매팅 시도 (userEncMsg 제외, 잘린 JSON 처리)
       if let jsonString = prettyPrintedJSON(from: requestInfo, excludingKey: ["userEncMsg","ci"]),
          jsonString != requestInfo {
           return jsonString
       }
       
       // HashMap.toString() 포매팅 시도 (userEncMsg 제외)
       if requestInfo.hasPrefix("{") && requestInfo.hasSuffix("}") {
           return formatHashMapString(requestInfo, excludingKey: ["userEncMsg","ci"])
       }
       
       // JSON도 HashMap도 아닌 경우 원본 출력
       return requestInfo
   }

   // JSON 포매팅 함수 (잘린 JSON 보정 및 특정 키 제외)
    static func prettyPrintedJSON(from jsonString: String, excludingKey key: [String]) -> String? {
       // JSON 문자열이 끝까지 완전하지 않을 경우 마지막을 제거
       var validJSONString = jsonString
        // }로 끝나지 않으면 쉼표 이전까지 자름
        if validJSONString.last != "}" {
            if let lastCommaIndex = validJSONString.lastIndex(of: ",") {
                validJSONString = String(validJSONString[..<lastCommaIndex])
                validJSONString.append("}") // 마지막을 }로 닫아줌
            }
        }
       
       // JSON으로 파싱 시도
       if let jsonData = validJSONString.data(using: .utf8),
          var jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
           
           key.forEach {item in
               jsonObject.removeValue(forKey: item)
           } // userEncMsg 키 제거
//           jsonObject.removeValue(forKey: key) // userEncMsg 키 제거
           
           if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) {
               return prettyString
           }
       }
       return nil // JSON 포맷이 아니면 nil 반환
   }

   // HashMap.toString() 포매팅 함수 (특정 키 제외)
    static func formatHashMapString(_ hashMapString: String, excludingKey key: [String]) -> String {
       // String을 key-value로 파싱
       let trimmedString = hashMapString.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
       var keyValues = trimmedString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
       
        key.forEach{key in
            keyValues.removeAll { $0.hasPrefix("\(key)=") }
        }
//       keyValues.removeAll { $0.hasPrefix("\(key)=") }
        
        // 남은 key-value 쌍 다시 조합
        let formattedString = keyValues.map { keyValue -> String in
            let parts = keyValue.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                return "\"\(parts[0])\" : \"\(parts[1])\""
            }else{
                return "\"\(parts[0])\" : \"\""
            }
            //return keyValue // 만약 쌍이 없을 경우 원본 반환
        }.joined(separator: ",\n\t")
        
       return "{\n\t\(formattedString)\n}"
   }
    
    static func getCurrentDateString(_ format:String,_ date:Date?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date ?? Date())
    }
    
    static func getCurrentDateString() -> String {
        return getCurrentDateString("yyyyMMdd", Date())
    }
    
    static func getFormattedDateString(_ date: Date) -> String {
        return getCurrentDateString("yyyy-MM-dd", date)
    }
    
    static func convertToFormattedDate(_ input: String?) -> String {
        // 입력 형식의 DateFormatter 설정
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd"
        
        // 출력 형식의 DateFormatter 설정
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"
        
        if(input == nil){
            return ""
        }
        // 입력 문자열을 Date 객체로 변환
        if let date = inputFormatter.date(from: input!) {
            // Date 객체를 yyyy-MM-dd 형식의 문자열로 변환
            return outputFormatter.string(from: date)
        } else {
            return ""
        }
    }
    
    static func combineTodayWithTime(_ time: String) -> Date? {
        let today = Date() // 오늘 날짜
        let calendar = Calendar.current
        
        // 시각 형식 변환기 설정
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmmss" // "080101"에 맞는 형식
        timeFormatter.timeZone = TimeZone.current
        timeFormatter.locale = Locale(identifier: "ko_KR")
        
        guard let timeOnly = timeFormatter.date(from: time) else {
            return nil // 형식이 잘못된 경우
        }
        
        // 오늘의 날짜와 파라미터 시각 결합
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: timeOnly)
        
        var combinedComponents = todayComponents
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return calendar.date(from: combinedComponents)
    }
    
    static func convertFromDateIntoString(_ date: Double?) -> String {
        guard let date = date else {
            return ""
        }
        // 밀리초를 초 단위로 변환
        let timeInterval = date / 1000
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
    
    static func getDevTypeImg(_ type:String) -> String{
        switch type {
        case "local":
            return "gearshape.fill"
        case "dev":
            return "wrench.and.screwdriver"
        case "prod":
            return "airplane"
        default:
            return "network"
        }
    }
    
    static func getDevTypeColor(_ type:String) -> Color{
        switch type {
        case "local":
            return .green
        case "dev":
            return .blue
        case "prod":
            return .purple
        default:
            return .secondary
        }
    }
}
