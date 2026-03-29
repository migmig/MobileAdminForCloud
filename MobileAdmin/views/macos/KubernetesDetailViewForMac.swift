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
    @State private var inspectorMode: KubernetesInspectorMode = .overview

    var body: some View {
        content
    }

    private var content: some View {
        List {
            inspectorModeSection

            Section("Context") {
                InfoRow(title: "Current Context", value: viewModel.selectedKubeContext)

                if let error = viewModel.kubernetesError, !error.isEmpty {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            if inspectorMode == .overview, let deployment = nav.selectedKubeDeployment {
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

            if inspectorMode == .ops, let deployment = nav.selectedKubeDeployment {
                Section("Rollout Status") {
                    if viewModel.isKubernetesActionLoading {
                        ProgressView()
                    } else if viewModel.selectedRolloutStatus.isEmpty {
                        Text("롤아웃 상태가 없습니다")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(viewModel.selectedRolloutStatus)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
            }

            if inspectorMode == .overview, let service = nav.selectedKubeService {
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

            if inspectorMode == .overview, let configMap = nav.selectedKubeConfigMap {
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

            if inspectorMode == .overview, let secret = nav.selectedKubeSecret {
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

            if inspectorMode == .overview, let pod = nav.selectedKubePod {
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

            }

            if inspectorMode == .ops, let pod = nav.selectedKubePod {
                Section("Logs") {
                    ScrollView {
                        Text(viewModel.selectedPodLogs.isEmpty ? "로그가 없습니다" : viewModel.selectedPodLogs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 240)
                }
            }

            if inspectorMode == .ops, nav.selectedKubeDeployment != nil || nav.selectedKubePod != nil {
                Section("Events") {
                    if viewModel.isKubernetesActionLoading {
                        ProgressView()
                    } else if viewModel.kubeEvents.isEmpty {
                        Text("이벤트가 없습니다")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.kubeEvents) { event in
                            KubernetesEventRow(event: event)
                        }
                    }
                }
            }

            if inspectorMode == .describe {
                Section("Describe") {
                    if viewModel.isKubernetesDocumentLoading {
                        ProgressView()
                    } else if selectedResourceSupportsDescribe {
                        RawKubernetesTextView(
                            text: viewModel.selectedDescribeText,
                            emptyText: "Describe 내용이 없습니다"
                        )
                    } else {
                        Text("이 리소스는 Describe를 지원하지 않습니다")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if inspectorMode == .yaml {
                Section("YAML") {
                    if viewModel.isKubernetesDocumentLoading {
                        ProgressView()
                    } else if selectedResourceSupportsYAML {
                        RawKubernetesTextView(
                            text: viewModel.selectedYAMLText,
                            emptyText: "YAML 내용이 없습니다"
                        )
                    } else {
                        Text("이 리소스는 YAML 보기를 지원하지 않습니다")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Kubernetes Detail")
        .onChange(of: nav.selectedKubeDeployment) { _, newValue in
            viewModel.selectedKubeDeployment = newValue
            replicaCount = newValue?.replicas ?? 1
            resetInspectorModeForCurrentSelection()
        }
        .onChange(of: nav.selectedKubePod) { _, newValue in
            viewModel.selectedKubePod = newValue
            resetInspectorModeForCurrentSelection()
        }
        .onChange(of: nav.selectedKubeService) { _, newValue in
            viewModel.selectedKubeService = newValue
            resetInspectorModeForCurrentSelection()
        }
        .onChange(of: nav.selectedKubeConfigMap) { _, newValue in
            viewModel.selectedKubeConfigMap = newValue
            resetInspectorModeForCurrentSelection()
        }
        .onChange(of: nav.selectedKubeSecret) { _, newValue in
            viewModel.selectedKubeSecret = newValue
            revealedSecretKeys = []
            resetInspectorModeForCurrentSelection()
        }
    }

    private var inspectorModeSection: some View {
        Section("Inspector") {
            Picker("Mode", selection: $inspectorMode) {
                Text("Overview").tag(KubernetesInspectorMode.overview)
                if selectedResourceSupportsOps {
                    Text("Ops").tag(KubernetesInspectorMode.ops)
                }
                if selectedResourceSupportsDescribe {
                    Text("Describe").tag(KubernetesInspectorMode.describe)
                }
                if selectedResourceSupportsYAML {
                    Text("YAML").tag(KubernetesInspectorMode.yaml)
                }
            }
        }
    }

    private var selectedResourceSupportsDescribe: Bool {
        nav.selectedKubePod != nil || nav.selectedKubeDeployment != nil
    }

    private var selectedResourceSupportsOps: Bool {
        nav.selectedKubePod != nil || nav.selectedKubeDeployment != nil
    }

    private var selectedResourceSupportsYAML: Bool {
        nav.selectedKubePod != nil || nav.selectedKubeDeployment != nil || nav.selectedKubeService != nil
    }

    private func resetInspectorModeForCurrentSelection() {
        if inspectorMode == .ops, !selectedResourceSupportsOps {
            inspectorMode = .overview
        } else if inspectorMode == .describe, !selectedResourceSupportsDescribe {
            inspectorMode = .overview
        } else if inspectorMode == .yaml, !selectedResourceSupportsYAML {
            inspectorMode = .overview
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

private enum KubernetesInspectorMode: String, CaseIterable, Identifiable {
    case overview
    case ops
    case describe
    case yaml

    var id: String { rawValue }
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

private struct KubernetesEventRow: View {
    let event: KubernetesEventInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.type)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(event.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(event.timestampText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(event.message)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
        }
        .padding(.vertical, 2)
    }
}

private struct RawKubernetesTextView: View {
    let text: String
    let emptyText: String

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? emptyText : text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .frame(minHeight: 240)
    }
}

#Preview {
    KubernetesDetailViewForMac()
        .environmentObject(ViewModel())
        .environmentObject(NavigationState())
}
