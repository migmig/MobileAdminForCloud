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
    static var baseUrl: String {
        switch current {
        case .production:
            return "https://untact.gcgf.or.kr:3002"
        case .development:
            return "http://172.16.111.7:8080"
        case .local:
            return "http://192.168.0.2:8080"
        }
    }
    #if DEBUG
    static var current: EnvironmentType = .development
    #else
    static var current: EnvironmentType = .production
    #endif
}
