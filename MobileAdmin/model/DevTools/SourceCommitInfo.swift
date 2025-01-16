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
struct SourceCommitInfo: Codable,Hashable {
    let result: SourceCommitInfoResult
    init(){
        self.result = SourceCommitInfoResult()
    }
}

// MARK: - SourceCommitInfoResult
struct SourceCommitInfoResult: Codable,Hashable {
    let total: Int
    let repository: [SourceCommitInfoRepository]
    init(){
        total = 0
        repository = []
    }
}

// MARK: - SourceCommitInfoRepository
struct SourceCommitInfoRepository: Codable,Hashable {
    let id: Int
    let name: String
    let permission: String?
    let actionName: String?
    init(){
        id = 0
        name = ""
        permission = ""
        actionName = ""
    }
    init(id:Int,name:String,permission:String,actionName:String){
        self.id = id
        self.name = name
        self.permission = permission
        self.actionName = actionName
    }
}
