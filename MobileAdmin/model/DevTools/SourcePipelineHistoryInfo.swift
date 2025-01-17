//
//  SourcePipelineHistoryInfo.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/17/25.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sourcePipelineHistoryInfo = try? JSONDecoder().decode(SourcePipelineHistoryInfo.self, from: jsonData)

import Foundation

// MARK: - SourcePipelineHistoryInfo
struct SourcePipelineHistoryInfo: Codable,Hashable {
    let result: SourcePipelineHistoryInfoResult
    init(){
        self.result = SourcePipelineHistoryInfoResult()
    }
}

// MARK: - SourcePipelineHistoryInfoResult
struct SourcePipelineHistoryInfoResult: Codable,Hashable {
    let historyList: [SourcePipelineHistoryInfoHistoryList]
    init(){
        historyList = []
    }
}

// MARK: - SourcePipelineHistoryInfoHistoryList
struct SourcePipelineHistoryInfoHistoryList: Codable,Hashable {
    let projectId: Int
    let id: Int
    let requestType: String
    let requestId: String
    let begin: Double
    let end: Double
    let status: String
}
