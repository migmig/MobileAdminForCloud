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
        ZStack{
//            // 카드 배경
//            RoundedRectangle(cornerRadius: 1)
//                .fill(
//                    MeshGradient(
//                        width: 3,
//                        height: 3,
//                        points: [
//                            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
//                            [0.0, 0.1], [0.5, 0.5], [1.0, 0.9],
//                            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
//                        ],
//                        colors: [
//                            .yellow, .yellow,  .yellow,
//                            .blue, .blue,  .blue,
//                            .green, .green, .green
//                        ]
//
//                    )
//                ).ignoresSafeArea()
            VStack{
                CloseButton(isPresented: $isPresented)
                    Text("URL 설정")
                        .font(.title)
                        .foregroundColor(.primary)
                        .padding()
                
                    // 운영 URL 입력
                VStack(alignment: .leading) {
                    Text("운영 URL")
                        .font(.headline)
                        .foregroundColor(.primary)
                    TextField("운영", text: $prodUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .cornerRadius(8)
                    
                }
                
                // 개발 URL 입력
                VStack(alignment: .leading) {
                    Text("개발 URL")
                        .font(.headline)
                        .foregroundColor(.primary)
                    TextField("개발", text: $devUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .cornerRadius(8)
                }
                
                
                // 로컬 URL 입력
                VStack(alignment: .leading) {
                    Text("로컬 URL")
                        .font(.headline)
                        .foregroundColor(.primary)
                    TextField("로컬", text: $localUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .cornerRadius(8)
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
                .font(.title2)
//                .foregroundColor(.secondary)
                .padding()
                .background(.selection)
                .cornerRadius(10)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
    }
}

#Preview {
    EnvSetView(isPresented:.constant(false))
}
