//
//  SettingsDetailsView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/10/24.
//

import SwiftUI
import Logging

struct SettingsDetailsView: View {
    let title : String
    @AppStorage("serverType") var serverType:String = "dev"
    @State private var isProduction:   Bool = false
    @State private var isDevelopment:  Bool = false
    @State private var isLocal:        Bool = false
    let logger = Logger(label:"com.migmig.MobileAdmin.SettingsDetailsView")
    
    init(title: String) {
        self.title = title
        self.isProduction = false
        self.isDevelopment = false
        self.isLocal = false
    }
    var body: some View {
        VStack(alignment: .leading) { 
            Toggle("운영 환경", isOn: $isProduction)
                .onChange(of: isProduction) { value in
                    if value {
                        EnvironmentConfig.current = .production
                        isDevelopment = false
                        isLocal = false
                        ViewModel.token = nil
                        serverType = "prod"
                    }
                }
                .padding()
            
            Toggle("개발 환경", isOn: $isDevelopment)
                .onChange(of: isDevelopment) { value in
                    if value {
                        EnvironmentConfig.current = .development
                        isProduction = false
                        isLocal = false
                        ViewModel.token = nil
                        serverType = "dev"
                    }
                }
                .padding()

            Toggle("로컬 환경", isOn: $isLocal)
                .onChange(of: isLocal) { value in
                    if value {
                        EnvironmentConfig.current = .local
                        isDevelopment = false
                        isProduction = false
                        ViewModel.token = nil
                        serverType = "local"
                    }
                }
                .padding()
        }
        .padding()
        .navigationTitle(title)
        .onAppear{
            logger.info("serverType:\(serverType)")
            switch(serverType){
            case "local":
                isLocal = true
                EnvironmentConfig.current = .local
            case "dev":
                isDevelopment = true
                EnvironmentConfig.current = .development
            case "prod":
                isProduction = true
                EnvironmentConfig.current = .production
            default:
                #if DEBUG
                isDevelopment = true
                EnvironmentConfig.current = .development
                #else
                isProduction = true
                EnvironmentConfig.current = .production
                #endif
            }
        }
    }
}
 
