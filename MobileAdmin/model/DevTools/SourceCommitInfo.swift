//
//  SourceCommitInfo.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/16/25.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sourceCommitInfo = try? JSONDecoder().decode(SourceCommitInfo.self, from: jsonData)

import Foundation

// MARK: - SourceCommitInfo
struct SourceCommitInfo: Hashable {
    let result: SourceCommitInfoResult?
}

// MARK: - SourceCommitInfoResult
struct SourceCommitInfoResult: Hashable {
    let total: Int?
    let repository: [SourceCommitInfoRepository]?
}

// MARK: - SourceCommitInfoRepository
struct SourceCommitInfoRepository: Hashable {
    let id: Int?
    let name: String?
    let permission: String?
    let actionName: String?
}
