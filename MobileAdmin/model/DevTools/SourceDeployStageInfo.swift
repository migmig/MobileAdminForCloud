//
//  SourceDeployStageInfo.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/21/25.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sourceDeployStageInfo = try? JSONDecoder().decode(SourceDeployStageInfo.self, from: jsonData)

import Foundation

// MARK: - SourceDeployStageInfo
struct SourceDeployStageInfo: Codable,Hashable {
    let result: SourceDeployStageInfoResult?
    init(){
        result = SourceDeployStageInfoResult()
    }
}

// MARK: - SourceDeployStageInfoResult
struct SourceDeployStageInfoResult: Codable,Hashable {
    let project: SourceDeployStageInfoProject?
    let stageList: [SourceDeployStageInfoProject]?
    init(){
        project = SourceDeployStageInfoProject()
        stageList = []
    }
}

// MARK: - SourceDeployStageInfoProject
struct SourceDeployStageInfoProject: Codable,Hashable {
    let id: Int
    let name: String
    init(){
        id = 0
        name = ""
    }
}
