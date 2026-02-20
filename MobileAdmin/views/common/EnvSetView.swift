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
    @State var prodUrl: String = (
        EnvironmentConfig.environmentUrls[.production] ?? ""
    )
    @State var devUrl: String = (
        EnvironmentConfig.environmentUrls[.development] ?? ""
    )
    @State var localUrl: String = (
        EnvironmentConfig.environmentUrls[.local] ?? ""
    )
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var isSaving = false
    @State private var saveResult: SaveResult? = nil

    private enum SaveResult {
        case success
        case failure(String)
    }

    private var allUrlsValid: Bool {
        isValidUrl(prodUrl) && isValidUrl(devUrl) && isValidUrl(localUrl)
    }

    private func isValidUrl(_ urlString: String) -> Bool {
        guard !urlString.isEmpty else { return true } // 빈 문자열 허용
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              (scheme == "http" || scheme == "https"),
              url.host != nil
        else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
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
                            url: $prodUrl,
                            isValid: isValidUrl(prodUrl)
                        )

                        EnvUrlField(
                            label: "개발",
                            placeholder: "https://dev.example.com",
                            systemImage: "wrench.and.screwdriver",
                            accentColor: AppColor.envDev,
                            url: $devUrl,
                            isValid: isValidUrl(devUrl)
                        )

                        EnvUrlField(
                            label: "로컬",
                            placeholder: "http://localhost:8080",
                            systemImage: "desktopcomputer",
                            accentColor: AppColor.envLocal,
                            url: $localUrl,
                            isValid: isValidUrl(localUrl)
                        )
                    }

                    // 저장 결과 메시지
                    if let result = saveResult {
                        switch result {
                        case .success:
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("저장되었습니다")
                            }
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.success)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        case .failure(let msg):
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(msg)
                            }
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.error)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
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
                    .disabled(isSaving || !allUrlsValid)
                }
                .padding(AppSpacing.xl)
            }
            .groupedBackground()
            .navigationTitle("서버 URL 설정")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func saveUrls() {
        isSaving = true
        saveResult = nil

        EnvironmentConfig.environmentUrls[.production] = prodUrl
        EnvironmentConfig.environmentUrls[.development] = devUrl
        EnvironmentConfig.environmentUrls[.local] = localUrl

        EnvironmentConfig.environmentUrls.forEach { type, url in
            if let existingSession = allEnvironment.first(
                where: { $0.envType == type.rawValue })
            {
                existingSession.url = url
            } else {
                let newSession = EnvironmentModel()
                newSession.envType = type.rawValue
                newSession.url = url
                modelContext.insert(newSession)
            }
        }

        do {
            try modelContext.save()
            withAnimation {
                saveResult = .success
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                isPresented = false
            }
        } catch {
            withAnimation {
                saveResult = .failure("저장 실패: \(error.localizedDescription)")
            }
        }

        isSaving = false
    }
}

// MARK: - URL 입력 필드 컴포넌트
private struct EnvUrlField: View {
    var label: String
    var placeholder: String
    var systemImage: String
    var accentColor: Color
    @Binding var url: String
    var isValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .foregroundColor(.white)
                    .font(.caption)
                    .frame(width: AppIconSize.sm, height: AppIconSize.sm)
                    .background(accentColor.gradient)
                    .cornerRadius(AppRadius.xs)

                Text(label)
                    .font(AppFont.listTitle)

                Spacer()

                if !url.isEmpty && !isValid {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(AppColor.error)
                        .font(.caption)
                }
            }

            TextField(placeholder, text: $url)
                .textFieldStyle(.roundedBorder)
                .font(AppFont.body)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                #endif

            if !url.isEmpty && !isValid {
                Text("올바른 URL 형식이 아닙니다 (http:// 또는 https://)")
                    .font(.caption2)
                    .foregroundColor(AppColor.error)
            }
        }
        .padding(AppSpacing.lg)
        .cardBackground()
        .cornerRadius(AppRadius.lg)
    }
}

#Preview {
    EnvSetView(isPresented: .constant(false))
}
