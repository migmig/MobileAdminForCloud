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
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // 헤더
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)

                    Text("서버 URL 설정")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("각 환경별 서버 URL을 입력하세요")
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, AppSpacing.xl)

                // URL 입력 카드들
                VStack(spacing: AppSpacing.md) {
                    EnvUrlField(
                        label: "운영",
                        placeholder: "https://production.example.com",
                        systemImage: "shield.checkered",
                        accentColor: AppColor.envProd,
                        url: $prodUrl
                    )

                    EnvUrlField(
                        label: "개발",
                        placeholder: "https://dev.example.com",
                        systemImage: "wrench.and.screwdriver",
                        accentColor: AppColor.envDev,
                        url: $devUrl
                    )

                    EnvUrlField(
                        label: "로컬",
                        placeholder: "http://localhost:8080",
                        systemImage: "desktopcomputer",
                        accentColor: AppColor.envLocal,
                        url: $localUrl
                    )
                }

                // 저장 버튼
                Button(action: saveUrls) {
                    HStack(spacing: AppSpacing.sm) {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("저장")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSaving)

                // 닫기 버튼 (sheet 모드일 때)
                if isPresented {
                    Button("닫기") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(AppSpacing.xl)
        }
        #if os(iOS)
        .background(Color(.systemGroupedBackground))
        #endif
    }

    private func saveUrls() {
        isSaving = true
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
        isSaving = false
        isPresented = false
    }
}

// MARK: - URL 입력 필드 컴포넌트
private struct EnvUrlField: View {
    var label: String
    var placeholder: String
    var systemImage: String
    var accentColor: Color
    @Binding var url: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .foregroundColor(.white)
                    .font(.caption)
                    .frame(width: 24, height: 24)
                    .background(accentColor.gradient)
                    .cornerRadius(6)

                Text(label)
                    .font(AppFont.listTitle)
            }

            TextField(placeholder, text: $url)
                .textFieldStyle(.roundedBorder)
                .font(AppFont.body)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                #endif
        }
        .padding(AppSpacing.lg)
        #if os(iOS)
        .background(Color(.secondarySystemGroupedBackground))
        #else
        .background(Color(.controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }
}

#Preview {
    EnvSetView(isPresented:.constant(false))
}
