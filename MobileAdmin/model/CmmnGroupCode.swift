//
//  CmmnGroupCode.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let cmmnGroupCode = try? JSONDecoder().decode(CmmnGroupCode.self, from: jsonData)

import Foundation

// MARK: - CmmnGroupCode
struct CmmnGroupCodeItem: Codable,Hashable {
    let cmmnGroupCode:String
    let cmmnGroupCodeNm, groupEstbs1Value, groupEstbs2Value: String?
    let groupEstbs3Value, groupEstbs4Value, groupEstbs5Value, groupEstbs6Value: String?
    let groupEstbs7Value, useAt: String?
}

typealias CmmnGroupCode = [CmmnGroupCodeItem]
