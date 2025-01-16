//
//  SettingsDetailsView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/10/24.
//

import SwiftUI
import Logging
import SwiftData

struct SettingsDetailsView: View {
    let title : String
    @AppStorage("serverType") var serverType:EnvironmentType = .development
    @State private var isPresented = false
    
    var body: some View {
        List {
            Picker("환경설정변경", selection: $serverType) {
                Label("운영환경", systemImage: Util.getDevTypeImg("prod")) 
                    .tag(EnvironmentType.production)
                Label("개발환경", systemImage: Util.getDevTypeImg("dev"))
                    .tag(EnvironmentType.development)
                Label("로컬환경", systemImage: Util.getDevTypeImg("local"))
                    .tag(EnvironmentType.local)
            }
            .onChange(of:serverType){oldvalue,newValue in
                EnvironmentConfig.current = newValue
                ViewModel.token = nil
            }
            .font(.title)
            .pickerStyle(.inline)
            .padding()
            Button("URL 변경",systemImage: "gearshape.2") {
                isPresented = true
            }.sheet(isPresented: $isPresented, content: {
                EnvSetView(isPresented: $isPresented)
            })
        } // List
//        .ignoresSafeArea()
        .navigationTitle(title)
    }
}

#Preview{
    SettingsDetailsView(title:"ServerSetting")
}
