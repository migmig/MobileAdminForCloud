//
//  SourceCommitBranchInfo.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/16/25.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sourceCommitBranchInfo = try? JSONDecoder().decode(SourceCommitBranchInfo.self, from: jsonData)

import Foundation

// MARK: - SourceCommitBranchInfo
struct SourceCommitBranchInfo: Hashable,Codable {
    let result: SourceCommitBranchInfoResult
    init(){
        result = SourceCommitBranchInfoResult()
    }
}

// MARK: - SourceCommitBranchInfoResult
struct SourceCommitBranchInfoResult: Hashable,Codable {
    let resultDefault: String
    let branch: [String]
    init(){
        resultDefault = ""
        branch = []
    }
    enum CodingKeys: String, CodingKey {
        case resultDefault = "default"
        case branch
    }
    
}
