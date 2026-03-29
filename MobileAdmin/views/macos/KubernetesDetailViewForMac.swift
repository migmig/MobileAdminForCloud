import SwiftUI
#if os(macOS)
import AppKit
#endif

struct KubernetesDetailViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState
    @State private var replicaCount: Int = 1
    @State private var showDeleteConfirmation = false
    @State private var revealedSecretKeys: Set<String> = []

    var body: some View {
        content
    }

    private var content: some View {
        List {
            Section("Context") {
                InfoRow(title: "Current Context", value: viewModel.selectedKubeContext)

                if let error = viewModel.kubernetesError, !error.isEmpty {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            if let deployment = nav.selectedKubeDeployment {
                Section("Deployment") {
                    InfoRow(title: "이름", value: deployment.name)
                    InfoRow(title: "Ready", value: "\(deployment.readyReplicas)/\(deployment.replicas)")
                    Stepper("Replica: \(replicaCount)", value: $replicaCount, in: 0...50)

                    Button("Scale") {
                        Task {
                            do {
                                try await viewModel.scaleSelectedDeployment(to: replicaCount)
                                await viewModel.refreshKubernetesOverview()
                            } catch {
                                await MainActor.run {
                                    viewModel.kubernetesError = error.localizedDescription
                                }
                            }
                        }
                    }

                    Button("Rollout Restart") {
                        Task {
                            do {
                                try await viewModel.restartSelectedDeployment()
                                await viewModel.refreshKubernetesOverview()
                            } catch {
                                await MainActor.run {
                                    viewModel.kubernetesError = error.localizedDescription
                                }
                            }
                        }
                    }
                }
            }

            if let service = nav.selectedKubeService {
                Section("Service") {
                    InfoRow(title: "이름", value: service.name)
                    InfoRow(title: "타입", value: service.type)
                    InfoRow(title: "주소", value: service.primaryAddress)
                    InfoRow(title: "포트 수", value: "\(service.portCount)")
                    if let externalAddress = service.externalAddress {
                        InfoRow(title: "외부 주소", value: externalAddress)
                    }
                }
            }

            if let configMap = nav.selectedKubeConfigMap {
                Section("ConfigMap") {
                    InfoRow(title: "이름", value: configMap.name)
                    InfoRow(title: "Immutable", value: configMap.immutable ? "true" : "false")
                    ForEach(configMap.textKeyNames, id: \.self) { key in
                        InfoRow(title: key, value: configMap.textData[key] ?? "")
                    }
                    ForEach(configMap.binaryKeyNames, id: \.self) { key in
                        InfoRow(title: "binary", value: key)
                    }
                }
            }

            if let secret = nav.selectedKubeSecret {
                Section("Secret") {
                    InfoRow(title: "이름", value: secret.name)
                    InfoRow(title: "타입", value: secret.type)
                    InfoRow(title: "Immutable", value: secret.immutable ? "true" : "false")
                    ForEach(secret.keyNames, id: \.self) { key in
                        SecretKeyRow(
                            key: key,
                            secret: secret,
                            isRevealed: revealedSecretKeys.contains(key),
                            onToggleReveal: { toggleReveal(for: key) },
                            onCopy: { copySecretValue(secret, key: key) }
                        )
                    }
                    Text("Secret 값은 기본적으로 가려져 있으며 키별로만 명시적으로 표시합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let pod = nav.selectedKubePod {
                Section("Pod") {
                    InfoRow(title: "이름", value: pod.name)
                    InfoRow(title: "상태", value: pod.phase)
                    Button("Delete Pod", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .confirmationDialog("선택한 Pod를 삭제하시겠습니까?", isPresented: $showDeleteConfirmation) {
                        Button("삭제", role: .destructive) {
                            Task {
                                do {
                                    try await viewModel.deleteSelectedPod()
                                    await viewModel.refreshKubernetesOverview()
                                } catch {
                                    await MainActor.run {
                                        viewModel.kubernetesError = error.localizedDescription
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Logs") {
                    ScrollView {
                        Text(viewModel.selectedPodLogs.isEmpty ? "로그가 없습니다" : viewModel.selectedPodLogs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 240)
                }
            }
        }
        .navigationTitle("Kubernetes Detail")
        .onChange(of: nav.selectedKubeDeployment) { _, newValue in
            viewModel.selectedKubeDeployment = newValue
            replicaCount = newValue?.replicas ?? 1
        }
        .onChange(of: nav.selectedKubeSecret) { _, _ in
            revealedSecretKeys = []
        }
    }

    private func toggleReveal(for key: String) {
        if revealedSecretKeys.contains(key) {
            revealedSecretKeys.remove(key)
        } else {
            revealedSecretKeys.insert(key)
        }
    }

    private func copySecretValue(_ secret: KubernetesSecretInfo, key: String) {
        let value = secret.copyableValue(for: key, isRevealed: revealedSecretKeys.contains(key)) ?? ""
        copyToPasteboard(value)
    }

    private func copyToPasteboard(_ value: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #endif
    }
}

private struct SecretKeyRow: View {
    let key: String
    let secret: KubernetesSecretInfo
    let isRevealed: Bool
    let onToggleReveal: () -> Void
    let onCopy: () -> Void

    private var displayValue: String {
        isRevealed ? (secret.decodedValue(for: key) ?? "디코드 실패") : "••••••••"
    }

    private var copyValue: String? {
        secret.copyableValue(for: key, isRevealed: isRevealed)
    }

    @ViewBuilder
    private var valueText: some View {
        if isRevealed {
            Text(displayValue)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        } else {
            Text(displayValue)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(key)
                valueText
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button(isRevealed ? "Hide" : "Reveal", action: onToggleReveal)
                Button("Copy", action: onCopy)
                    .disabled(copyValue == nil)
            }
        }
    }
}

#Preview {
    KubernetesDetailViewForMac()
        .environmentObject(ViewModel())
        .environmentObject(NavigationState())
}
