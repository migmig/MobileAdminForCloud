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
    @State  private var isProduction:   Bool = false
    @State  private var isDevelopment:  Bool = false
    @State  private var isLocal:        Bool = false
    let logger = Logger(label:"com.migmig.MobileAdmin.SettingsDetailsView")
    
    var body: some View {
        
        Section(header: Text("환경 설정").font(.headline)) {
            Text("현재 설정된 서버 환경 : \(serverType)")
                .padding()
        }
        Section(header: Text("환경 설정 변경").font(.headline)) {
            Toggle("운영 환경", isOn: $isProduction)
                .onChange(of: isProduction) { value in
                    if value {
                        EnvironmentConfig.current = .production
                        isDevelopment = false
                        isLocal = false
                        isProduction = true
                        ViewModel.token = nil
                        serverType = "prod"
                    }
                }
                .padding()
            
            Divider()
            
            Toggle("개발 환경", isOn: $isDevelopment)
                .onChange(of: isDevelopment) { value in
                    if value {
                        EnvironmentConfig.current = .development
                        isProduction = false
                        isLocal = false
                        isDevelopment = true
                        ViewModel.token = nil
                        serverType = "dev"
                    }
                }
                .padding()
            
            Divider()
            
            Toggle("로컬 환경", isOn: $isLocal)
                .onChange(of: isLocal) { value in
                    if value {
                        EnvironmentConfig.current = .local
                        isDevelopment = false
                        isProduction = false
                        isLocal = true
                        ViewModel.token = nil
                        serverType = "local"
                    }
                }
                .padding()
                .onAppear(){
                    isProduction = (serverType == "prod")
                    isLocal = (serverType == "local")
                    isDevelopment = (serverType == "dev") 
                }
        }
    }
}

