//
//  SettingsDetailsView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/10/24.
//

import SwiftUI
import SwiftData

struct SettingsDetailsView: View {
    @AppStorage("serverType") var serverType: EnvironmentType = .development
    @State private var isPresented = false
    @State private var showSwitchConfirm = false
    @State private var pendingEnv: EnvironmentType? = nil

    private let envOptions: [(EnvironmentType, String, String, Color)] = [
        (.production,  "운영환경", "prod",  AppColor.envProd),
        (.development, "개발환경", "dev",   AppColor.envDev),
        (.local,       "로컬환경", "local", AppColor.envLocal),
    ]

    var body: some View {
        List {
            // MARK: - 현재 환경 상태 카드
            Section {
                currentEnvironmentCard
            }

            // MARK: - 환경 설정
            Section("환경 설정") {
                ForEach(envOptions, id: \.0) { type, label, key, color in
                    Button {
                        if serverType != type {
                            pendingEnv = type
                            showSwitchConfirm = true
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
                    .accessibilityLabel("\(label), \(serverType == type ? "선택됨" : "선택 안됨")")
                    .accessibilityAddTraits(serverType == type ? .isSelected : [])
                }
            }

            // MARK: - 서버 URL
            Section("서버 URL") {
                Button(action: { isPresented = true }) {
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
                .sheet(isPresented: $isPresented) {
                    EnvSetView(isPresented: $isPresented)
                }
            }

            // MARK: - 앱 정보
            Section("앱 정보") {
                appInfoRow(title: "버전", value: appVersion)
                appInfoRow(title: "빌드", value: appBuild)
                #if os(iOS)
                appInfoRow(title: "플랫폼", value: "iOS")
                #elseif os(macOS)
                appInfoRow(title: "플랫폼", value: "macOS")
                #endif
            }
        }
        .navigationTitle("설정")
        .confirmationDialog(
            "환경을 전환하시겠습니까?",
            isPresented: $showSwitchConfirm,
            titleVisibility: .visible
        ) {
            if let env = pendingEnv {
                let label = envOptions.first { $0.0 == env }?.1 ?? ""
                Button("\(label)(으)로 전환") {
                    withAnimation {
                        serverType = env
                        EnvironmentConfig.current = env
                        ViewModel.token = nil
                    }
                    pendingEnv = nil
                }
                Button("취소", role: .cancel) {
                    pendingEnv = nil
                }
            }
        } message: {
            Text("토큰이 초기화되며 재인증이 필요합니다.")
        }
    }

    // MARK: - 현재 환경 상태 카드
    private var currentEnvironmentCard: some View {
        let current = envOptions.first { $0.0 == serverType }
        let label = current?.1 ?? ""
        let key = current?.2 ?? ""
        let color = current?.3 ?? .blue

        return VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: Util.getDevTypeImg(key))
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: AppIconSize.lg, height: AppIconSize.lg)
                    .background(color.gradient)
                    .cornerRadius(AppRadius.md)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(label)
                        .font(AppFont.sectionTitle)
                        .fontWeight(.semibold)

                    Text(EnvironmentConfig.baseUrl)
                        .font(AppFont.mono)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 토큰 상태
                tokenStatusBadge
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - 토큰 상태 배지
    private var tokenStatusBadge: some View {
        let hasToken = ViewModel.token != nil
        let icon = hasToken ? "checkmark.shield.fill" : "xmark.shield.fill"
        let label = hasToken ? "인증됨" : "미인증"
        let color: Color = hasToken ? AppColor.success : AppColor.inactive

        return HStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(AppFont.captionSmall)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(color.opacity(0.12))
        .cornerRadius(AppRadius.sm)
    }

    // MARK: - 앱 정보 행
    private func appInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(AppFont.mono)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
}

#Preview {
    NavigationStack {
        SettingsDetailsView()
    }
}
