//
//  EnvSetView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/18/24.
//

import SwiftUI
import SwiftData

struct EnvSetView: View {
    @Query var allEnvironment: [EnvironmentModel]
    @State var prodUrl :String = (
        EnvironmentConfig.environmentUrls[.production] ?? ""
    )
    @State var devUrl :String = (
        EnvironmentConfig.environmentUrls[.development] ?? ""
    )
    @State var localUrl :String = (
        EnvironmentConfig.environmentUrls[.local] ?? ""
    )
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented:Bool
    var body: some View {
        VStack{
            InfoRow2(title: "운영: "){
                TextField("운영", text: $prodUrl)
            }
            InfoRow2(title: "개발: "){
                TextField("개발", text: $devUrl)
            }
            InfoRow2(title: "로컬: "){
                TextField("로컬", text: $localUrl)
            }
            Button("저장"){
                EnvironmentConfig.environmentUrls[.production] = prodUrl
                EnvironmentConfig.environmentUrls[.development] = devUrl
                EnvironmentConfig.environmentUrls[.local] = localUrl
                EnvironmentConfig.environmentUrls.forEach { type, url in
                    print("\(type.rawValue): \(url)")
                    
                    if let existsingSession = allEnvironment.first(
                        where: {$0.envType == type.rawValue})
                    {
                        existsingSession.url = url
                    }else{
                        let newSession = EnvironmentModel()
                        newSession.envType = type.rawValue
                        newSession.url = url
                        modelContext.insert(newSession)
                    }
                }
                do{
                    try modelContext.save()
                    print("저장 성공: ")
                }catch{
                    print("저장 실패: \(error.localizedDescription)")
                }
                isPresented = false
            }
        }
        .padding()
    }
}

#Preview {
    EnvSetView(isPresented:.constant(false))
}
