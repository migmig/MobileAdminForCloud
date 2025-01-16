//
//  CmmnCodeElement.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let cmmnCode = try? JSONDecoder().decode(CmmnCode.self, from: jsonData)

import Foundation

// MARK: - CmmnCodeElement
struct CmmnCodeItem: Codable  ,Identifiable{
    let cmmnCodeNm:String
    let cmmnEstbs1Value, cmmnEstbs2Value, cmmnEstbs3Value: String
    let cmmnEstbs4Value, cmmnEstbs5Value, cmmnEstbs6Value, cmmnEstbs7Value: String
    var idStruct: cmmnCodeID
    let sortOrdr: Int
    let upperCmmnCode, useAt: String    // Identifiable 요구사항을 충족하는 id 연산 프로퍼티
    var id: String {
        idStruct.cmmnCode
    }
    var cmmnCode:String {
        idStruct.cmmnCode
    }
    var cmmnGoupCode:String {
        idStruct.cmmnGoupCode
    }
    // CodingKeys 열거형 추가
      enum CodingKeys: String, CodingKey {
          case cmmnCodeNm
          case cmmnEstbs1Value
          case cmmnEstbs2Value
          case cmmnEstbs3Value
          case cmmnEstbs4Value
          case cmmnEstbs5Value
          case cmmnEstbs6Value
          case cmmnEstbs7Value
          case idStruct = "id"
          case sortOrdr
          case upperCmmnCode
          case useAt
      }

    // Custom decoding to replace nil with ""
       init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)

           cmmnCodeNm = try container.decode(String.self, forKey: .cmmnCodeNm)
           cmmnEstbs1Value = try container.decodeIfPresent(String.self, forKey: .cmmnEstbs1Value) ?? ""
           cmmnEstbs2Value = try container.decodeIfPresent(String.self, forKey: .cmmnEstbs2Value) ?? ""
           cmmnEstbs3Value = try container.decodeIfPresent(String.self, forKey: .cmmnEstbs3Value) ?? ""
           cmmnEstbs4Value = try container.decodeIfPresent(String.self, forKey: .cmmnEstbs4Value) ?? ""
           cmmnEstbs5Value = try container.decodeIfPresent(String.self, forKey: .cmmnEstbs5Value) ?? ""
           cmmnEstbs6Value = try container.decodeIfPresent(String.self, forKey: .cmmnEstbs6Value) ?? ""
           cmmnEstbs7Value = try container.decodeIfPresent(String.self, forKey: .cmmnEstbs7Value) ?? ""
           idStruct = try container.decode(cmmnCodeID.self, forKey: .idStruct)
           sortOrdr = try container.decode(Int.self, forKey: .sortOrdr)
           upperCmmnCode = try container.decodeIfPresent(String.self, forKey: .upperCmmnCode) ?? ""
           useAt = try container.decodeIfPresent(String.self, forKey: .useAt) ?? ""
       }
    
}

// MARK: - ID
struct cmmnCodeID: Codable {
    let cmmnCode, cmmnGoupCode: String
}

typealias CmmnCode = [CmmnCodeItem]
