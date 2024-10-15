//
//  SettingsDetailsView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/10/24.
//

import SwiftUI

struct SettingsDetailsView: View {
    let title : String
    
    @State private var isProduction: Bool = false
    @State private var isDevelopment: Bool = true
    @State private var isLocal: Bool = false

    var body: some View {
        VStack(alignment: .leading) { 
            Toggle("운영 환경", isOn: $isProduction)
                .onChange(of: isProduction) { value in
                    if value {
                        EnvironmentConfig.current = .production
                        isDevelopment = false
                        isLocal = false
                    }
                }
                .padding()
            
            Toggle("개발 환경", isOn: $isDevelopment)
                .onChange(of: isDevelopment) { value in
                    if value {
                        EnvironmentConfig.current = .development
                        isProduction = false
                        isLocal = false
                    }
                }
                .padding()

            Toggle("로컬 환경", isOn: $isLocal)
                .onChange(of: isLocal) { value in
                    if value {
                        EnvironmentConfig.current = .local
                        isDevelopment = false
                        isProduction = false
                    }
                }
                .padding()
        }
        .padding()
        .navigationTitle(title)
    }
}
 
