//
//  SourcePipelineExecResult.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/17/25.
//

import Foundation


struct SourcePipelineExecResult:Codable,Hashable{
    let result: SourcePipelineExecResultResult
    init(){
        result = SourcePipelineExecResultResult()
    }
}

struct SourcePipelineExecResultResult : Codable,Hashable{
    let historyId: Double
    init(){
        historyId = 0
    }
}
