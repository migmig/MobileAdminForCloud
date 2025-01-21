//
//  SourceDeployHistoryInfo.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/21/25.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sourceDeployHistoryInfo = try? JSONDecoder().decode(SourceDeployHistoryInfo.self, from: jsonData)

import Foundation

// MARK: - SourceDeployHistoryInfo
struct SourceDeployHistoryInfo: Codable,Hashable {
    let result: SourceDeployHistoryInfoResult?
    init(){
        result = SourceDeployHistoryInfoResult()
    }
}

// MARK: - SourceDeployHistoryInfoResult
struct SourceDeployHistoryInfoResult: Codable,Hashable {
    let historyList: [SourceDeployHistoryInfoHistoryList]?
    init(){
        historyList = []
    }
}

// MARK: - SourceDeployHistoryInfoHistoryList
struct SourceDeployHistoryInfoHistoryList: Codable,Hashable {
    let project: SourceDeployHistoryInfoProject?
    let stage: SourceDeployHistoryInfoProject?
    let scenario: SourceDeployHistoryInfoProject?
    let id: Int
    let startTime: Double
    let status: String
}

// MARK: - SourceDeployHistoryInfoProject
struct SourceDeployHistoryInfoProject: Codable,Hashable {
    let id: Int
    let name: String
    init(){
        id = 0
        name = ""
    }
}
