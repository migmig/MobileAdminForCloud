//
//  EnvironmentType.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/11/24.
//


import SwiftUI

enum EnvironmentType: String {
    case development
    case production
    case local
}



struct EnvironmentConfig {
   
    static var environmentUrls: [EnvironmentType: String] = [:]
    
    static func initializeUrls(from environments: [EnvironmentModel]) {
           environmentUrls = Dictionary(
               uniqueKeysWithValues: environments.compactMap { env in
                   guard let type = EnvironmentType(rawValue: env.envType) else { return nil }
                   return (type, env.url)
               }
           )
       }

    static var baseUrl: String {
        return environmentUrls[current] ?? "http://192.168.0.3:8080"  // 기본 URL 설정
    }
    #if DEBUG
    static var current: EnvironmentType = .production
    #else
    static var current: EnvironmentType = .production
    #endif
}
