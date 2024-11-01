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
    @AppStorage("serverType") var serverType:EnvironmentType = .development
    var body: some View {
        List {
            if #available(iOS 17.0, *) {
                Picker("환경설정변경", selection: $serverType) {
                    Text("운영환경").tag(EnvironmentType.production)
                    Text("개발환경").tag(EnvironmentType.development)
                    Text("로컬환경").tag(EnvironmentType.local)
                }
                .onChange(of:serverType){oldvalue,newValue in
                    EnvironmentConfig.current = newValue
                    ViewModel.token = nil
                }
                .font(.title)
                .pickerStyle(.inline)
                .padding()
            } else {
                // Fallback on earlier versions
            }
            
        } // List
        .navigationTitle(title)
    }
}

