//
//  SourceDeployExecResult.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/21/25.
//

import Foundation

struct SourceDeployExecResult: Codable,Hashable {
    let result: SourceDeployExecResultResult?
    init(){
        result = SourceDeployExecResultResult()
    }
}

struct SourceDeployExecResultResult: Codable,Hashable{
    let id: Int?
    init(){
        id = 0
    }
}
