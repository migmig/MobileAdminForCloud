//
//  SourceDeployScenarioInfo.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/21/25.
//


// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sourceDeployScenarioInfo = try? JSONDecoder().decode(SourceDeployScenarioInfo.self, from: jsonData)

import Foundation

// MARK: - SourceDeployScenarioInfo
struct SourceDeployScenarioInfo: Codable, Hashable {
    let result: SourceDeployScenarioInfoResult?
    init(){
        result = SourceDeployScenarioInfoResult()
    }
}

// MARK: - SourceDeployScenarioInfoResult
struct SourceDeployScenarioInfoResult: Codable,Hashable {
    let project: SourceDeployScenarioInfoProject?
    let stage: SourceDeployScenarioInfoProject?
    let scenarioList: [SourceDeployScenarioInfoProject]?
    init(){
        project = SourceDeployScenarioInfoProject()
        stage = SourceDeployScenarioInfoProject()
        scenarioList = []
    }
}

// MARK: - SourceDeployScenarioInfoProject
struct SourceDeployScenarioInfoProject: Codable,Hashable {
    let id: Int
    let name: String
    init(){
        id = 0
        name = ""
    }
}
