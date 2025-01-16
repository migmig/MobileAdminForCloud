//
//  EnvironmentModel.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/18/24.
//

import SwiftData

@Model
class EnvironmentModel{
    var envType : String
    var url : String
    init(){
        self.envType = ""
        self.url = ""
    }
}
