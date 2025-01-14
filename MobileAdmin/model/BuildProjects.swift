//
//  BuildProjects.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/13/25.
//


import Foundation

// MARK: - BuildProjects
struct BuildProjects : Codable,Hashable{
    let result: SourceBuildResult
    init(){
        result = SourceBuildResult(total: 0, project: [])
    }
}

// MARK: - Result
struct SourceBuildResult : Codable,Hashable{
    let total: Int
    let project: [SourceBuildProject]
}

// MARK: - Project
struct SourceBuildProject : Codable,Identifiable,Hashable{
    let id: Int
    let name:String
    let permission: String
    let actionName: String
    init(){
        id = 0
        name = ""
        permission = ""
        actionName = ""
    }
}

struct PiplelineProjectList : Codable,Hashable{
    let result: PiplelineResult
}

// MARK: - Result
struct PiplelineResult: Codable,Hashable {
    let projectList: [PiplelineProject]
}

// MARK: - ProjectList
struct PiplelineProject: Codable,Identifiable,Hashable {
    let name: String
    let id: Int
}
