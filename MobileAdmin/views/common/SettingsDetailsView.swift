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
            Section("설정"){
                Picker("환경설정변경", selection: $serverType) {
                    HStack{
                        Image(systemName: Util.getDevTypeImg("prod"))
                            .foregroundColor(Util.getDevTypeColor("prod"))
                        Spacer()
                        Text("운영환경")
                        Spacer()
                    }
                    .tag(EnvironmentType.production)
                    HStack{
                        Image(systemName: Util.getDevTypeImg("dev"))
                            .foregroundColor(Util.getDevTypeColor("dev"))
                        Spacer()
                        Text("개발환경")
                        Spacer()
                    }
                    .tag(EnvironmentType.development)
                    HStack{
                        Image(systemName: Util.getDevTypeImg("local"))
                            .foregroundColor(Util.getDevTypeColor("local"))
                        Spacer()
                        Text("로컬환경")
                        Spacer()
                    }
                    .tag(EnvironmentType.local)
                }
                .onChange(of:serverType){oldvalue,newValue in
                    EnvironmentConfig.current = newValue
                    ViewModel.token = nil
                }
                .font(.title)
                .pickerStyle(.inline)
                .padding()
            }
            Section("URL"){
                Button(action:{ isPresented = true}){
                    HStack{
                        Image(systemName: "gearshape.2")
                        Spacer()
                        Text("URL 변경")
                        Spacer()
                    }
                }.sheet(isPresented: $isPresented, content: {
                    EnvSetView(isPresented: $isPresented)
                })
            }
        } // List
//        .ignoresSafeArea()
        .navigationTitle(title)
    }
}

#Preview{
    SettingsDetailsView(title:"ServerSetting")
}
