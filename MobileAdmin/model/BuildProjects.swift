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
}

// MARK: - Result
struct SourceBuildResult : Codable,Hashable{
    let total: Int
    let project: [SourceBuildProject]
}

// MARK: - Project
struct SourceBuildProject : Codable,Identifiable,Hashable{
    let name, permission: String
    let id: Int
    let actionName: String
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
