//
//  SettingsDetailsView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/10/24.
//

import SwiftUI
import SwiftData

struct SettingsDetailsView: View {
    let title : String
    @AppStorage("serverType") var serverType:EnvironmentType = .development
    @State private var isPresented = false
    
    private let envOptions: [(EnvironmentType, String, String, Color)] = [
        (.production,  "운영환경", "prod",  AppColor.envProd),
        (.development, "개발환경", "dev",   AppColor.envDev),
        (.local,       "로컬환경", "local", AppColor.envLocal),
    ]

    var body: some View {
        List {
            Section("환경 설정"){
                ForEach(envOptions, id: \.0) { type, label, key, color in
                    Button {
                        withAnimation {
                            serverType = type
                        }
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: Util.getDevTypeImg(key))
                                .foregroundColor(.white)
                                .font(.caption)
                                .frame(width: AppIconSize.md, height: AppIconSize.md)
                                .background(color.gradient)
                                .cornerRadius(AppRadius.sm)

                            Text(label)
                                .font(AppFont.listTitle)
                                .foregroundColor(.primary)

                            Spacer()

                            if serverType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(color)
                                    .font(AppFont.listTitle)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                    .buttonStyle(.plain)
                }
                .onChange(of:serverType){oldvalue,newValue in
                    EnvironmentConfig.current = newValue
                    ViewModel.token = nil
                }
            }
            Section("서버 URL"){
                Button(action:{ isPresented = true}){
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "server.rack")
                            .foregroundColor(.white)
                            .font(.caption)
                            .frame(width: AppIconSize.md, height: AppIconSize.md)
                            .background(Color.secondary.gradient)
                            .cornerRadius(AppRadius.sm)

                        Text("URL 변경")
                            .font(AppFont.listTitle)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(AppFont.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isPresented, content: {
                    EnvSetView(isPresented: $isPresented)
                })
            }
        }
        .navigationTitle(title)
    }
}

#Preview{
    SettingsDetailsView(title:"ServerSetting")
}
