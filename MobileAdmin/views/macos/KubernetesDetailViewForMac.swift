import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

struct KubernetesDetailViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\KubernetesActionAuditEntry.timestamp, order: .reverse)])
    private var kubernetesAuditEntries: [KubernetesActionAuditEntry]

    @State private var replicaCount: Int = 1
    @State private var pendingKubernetesActionConfirmation: KubernetesMutationActionConfirmation?
    @State private var deletePodConfirmationInput: String = ""
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
                        pendingKubernetesActionConfirmation = .scale(
                            deploymentName: deployment.name,
                            namespace: viewModel.selectedKubeNamespace,
                            fromReplicas: deployment.replicas,
                            toReplicas: replicaCount
                        )
                    }

                    Button("Rollout Restart") {
                        pendingKubernetesActionConfirmation = .rolloutRestart(
                            deploymentName: deployment.name,
                            namespace: viewModel.selectedKubeNamespace
                        )
                    }
                }

            }

            if inspectorMode == .ops, nav.selectedKubeDeployment != nil {
                Section("Live Refresh") {
                    Toggle("Auto Refresh", isOn: $viewModel.isKubernetesAutoRefreshEnabled)
                    Text("\(Int(viewModel.kubernetesAutoRefreshInterval))초 간격으로 현재 선택 리소스를 갱신합니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Rollout Status") {
                    Button("Refresh") {
                        Task { await viewModel.loadSelectedDeploymentOperationalDetails() }
                    }

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
                        pendingKubernetesActionConfirmation = .deletePod(
                            podName: pod.name,
                            namespace: viewModel.selectedKubeNamespace
                        )
                        deletePodConfirmationInput = ""
                    }
                }

            }

            if selectedResourceSupportsMutationActions {
                actionConfirmationSection
                actionResultAndGuidanceSection
                localAuditHistorySection
            }

            if inspectorMode == .ops, nav.selectedKubePod != nil {
                Section("Live Refresh") {
                    Toggle("Auto Refresh", isOn: $viewModel.isKubernetesAutoRefreshEnabled)
                    Text("\(Int(viewModel.kubernetesAutoRefreshInterval))초 간격으로 현재 선택 리소스를 갱신합니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Logs") {
                    Button("Refresh") {
                        Task { await viewModel.refreshPodLogs() }
                    }

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
                    Button("Refresh") {
                        Task { await viewModel.refreshSelectedOperationsOnce() }
                    }

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

                        if nav.selectedKubeSecret != nil {
                            secretYAMLWarningSection
                            secretYAMLRevealSection
                        }
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
            pendingKubernetesActionConfirmation = nil
            deletePodConfirmationInput = ""
            resetInspectorModeForCurrentSelection()
        }
        .onChange(of: nav.selectedKubePod) { _, newValue in
            viewModel.selectedKubePod = newValue
            pendingKubernetesActionConfirmation = nil
            deletePodConfirmationInput = ""
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
        .onChange(of: viewModel.isKubernetesAutoRefreshEnabled) { _, isEnabled in
            if isEnabled {
                Task { await viewModel.startKubernetesAutoRefreshIfNeeded() }
            } else {
                viewModel.stopKubernetesAutoRefresh()
            }
        }
        .onChange(of: inspectorMode) { _, newValue in
            if newValue != .ops {
                viewModel.stopKubernetesAutoRefresh()
            }
        }
        .onDisappear {
            viewModel.stopKubernetesAutoRefresh()
        }
        .task {
            viewModel.configureKubernetesActionAuditSink { entry in
                modelContext.insert(entry)
                try? modelContext.save()
            }
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

    private var selectedResourceSupportsMutationActions: Bool {
        nav.selectedKubePod != nil || nav.selectedKubeDeployment != nil
    }

    private var selectedResourceSupportsYAML: Bool {
        nav.selectedKubePod != nil ||
        nav.selectedKubeDeployment != nil ||
        nav.selectedKubeService != nil ||
        nav.selectedKubeConfigMap != nil ||
        nav.selectedKubeSecret != nil
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

    private var secretYAMLWarningSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("경고")
                .font(.caption)
                .fontWeight(.semibold)
            Text("Secret YAML은 base64 인코딩 값을 raw 그대로 포함할 수 있습니다. decoded 값은 아래에서 key별로만 명시적으로 표시/복사하세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var secretYAMLRevealSection: some View {
        if let secret = nav.selectedKubeSecret {
            VStack(alignment: .leading, spacing: 8) {
                Text("Secret Keys")
                    .font(.caption)
                    .fontWeight(.semibold)

                ForEach(secret.keyNames, id: \.self) { key in
                    SecretKeyRow(
                        key: key,
                        secret: secret,
                        isRevealed: revealedSecretKeys.contains(key),
                        onToggleReveal: { toggleReveal(for: key) },
                        onCopy: { copySecretValue(secret, key: key) }
                    )
                }
            }
            .padding(.top, 8)
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

    private var actionConfirmationSection: some View {
        Section("Action Confirmation") {
            if let confirmation = pendingKubernetesActionConfirmation {
                Text(confirmation.title)
                    .font(.headline)

                ForEach(Array(confirmation.summaryLines.enumerated()), id: \.offset) { _, summary in
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if case let .deletePod(podName, _) = confirmation {
                    TextField("Pod 이름 입력 (\(podName))", text: $deletePodConfirmationInput)
                    Text("삭제를 진행하려면 Pod 이름을 정확히 입력하세요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Cancel") {
                        pendingKubernetesActionConfirmation = nil
                        deletePodConfirmationInput = ""
                    }

                    Spacer()

                    Button(confirmation.confirmButtonTitle, role: confirmation.buttonRole) {
                        Task {
                            await executeConfirmedAction(confirmation)
                        }
                    }
                    .disabled(!canExecutePendingConfirmation(confirmation) || viewModel.isKubernetesActionLoading)
                }
            } else {
                Text("Scale / Rollout Restart / Delete Pod 작업은 먼저 요약을 확인한 뒤 실행됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionResultAndGuidanceSection: some View {
        Section("Action Result") {
            if let pendingSummary = viewModel.pendingKubernetesActionSummary, viewModel.isKubernetesActionLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(pendingSummary)
                        .font(.caption)
                }
            }

            if let latestResult = viewModel.latestKubernetesActionResult {
                InfoRow(title: "Action", value: latestResult.actionType)
                InfoRow(title: "Resource", value: "\(latestResult.resourceKind)/\(latestResult.resourceName)")
                InfoRow(title: "Namespace", value: latestResult.namespace)

                HStack {
                    Text("Result")
                    Spacer()
                    Text(latestResult.status.displayText)
                        .fontWeight(.semibold)
                        .foregroundStyle(latestResult.status.displayColor)
                }

                if let errorSummary = latestResult.errorSummary, !errorSummary.isEmpty {
                    Text(errorSummary)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if let guidance = viewModel.latestKubernetesActionGuidance, !guidance.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rollback Guidance")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(guidance)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.latestKubernetesActionResult == nil,
               (viewModel.latestKubernetesActionGuidance ?? "").isEmpty,
               !viewModel.isKubernetesActionLoading {
                Text("최근 실행된 변경 작업 결과가 없습니다.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var localAuditHistorySection: some View {
        Section("Local Audit History") {
            if relevantAuditEntries.isEmpty {
                Text("로컬 감사 이력이 없습니다")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(relevantAuditEntries, id: \.persistentModelID) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(Self.auditDateFormatter.string(from: entry.timestamp))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(entry.result.localizedAuditResult)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(entry.result.auditResultColor)
                        }

                        Text("\(entry.actionType) · \(entry.resourceKind)/\(entry.resourceName)")
                            .font(.caption)

                        Text("Namespace: \(entry.namespace)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if let guidance = entry.rollbackGuidance, !guidance.isEmpty {
                            Text("Guidance: \(guidance)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var relevantAuditEntries: [KubernetesActionAuditEntry] {
        let filteredByNamespace = kubernetesAuditEntries.filter { entry in
            entry.namespace == viewModel.selectedKubeNamespace
        }

        let filteredByResource = filteredByNamespace.filter { entry in
            switch selectedAuditResource {
            case let .deployment(name):
                return entry.resourceKind == "Deployment" && entry.resourceName == name
            case let .pod(name):
                return entry.resourceKind == "Pod" && entry.resourceName == name
            case .none:
                return true
            }
        }

        return Array(filteredByResource.prefix(20))
    }

    private var selectedAuditResource: KubernetesAuditResource? {
        if let deployment = nav.selectedKubeDeployment {
            return .deployment(deployment.name)
        }

        if let pod = nav.selectedKubePod {
            return .pod(pod.name)
        }

        return nil
    }

    @MainActor
    private func executeConfirmedAction(_ confirmation: KubernetesMutationActionConfirmation) async {
        do {
            switch confirmation {
            case let .scale(_, _, _, targetReplicas):
                try await viewModel.scaleSelectedDeployment(to: targetReplicas)
            case .rolloutRestart:
                try await viewModel.restartSelectedDeployment()
            case .deletePod:
                try await viewModel.deleteSelectedPod()
            }

            await viewModel.refreshKubernetesOverview()
        } catch {
            await MainActor.run {
                if viewModel.kubernetesError?.isEmpty ?? true {
                    viewModel.kubernetesError = error.localizedDescription
                }
            }
        }

        pendingKubernetesActionConfirmation = nil
        deletePodConfirmationInput = ""
    }

    private func canExecutePendingConfirmation(_ confirmation: KubernetesMutationActionConfirmation) -> Bool {
        switch confirmation {
        case .deletePod(let podName, _):
            return deletePodConfirmationInput == podName
        case .scale, .rolloutRestart:
            return true
        }
    }

    private static let auditDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

private enum KubernetesInspectorMode: String, CaseIterable, Identifiable {
    case overview
    case ops
    case describe
    case yaml

    var id: String { rawValue }
}

private enum KubernetesAuditResource {
    case deployment(String)
    case pod(String)
}

private enum KubernetesMutationActionConfirmation: Identifiable {
    case scale(deploymentName: String, namespace: String, fromReplicas: Int, toReplicas: Int)
    case rolloutRestart(deploymentName: String, namespace: String)
    case deletePod(podName: String, namespace: String)

    var id: String {
        switch self {
        case let .scale(deploymentName, namespace, _, toReplicas):
            return "scale:\(namespace):\(deploymentName):\(toReplicas)"
        case let .rolloutRestart(deploymentName, namespace):
            return "rollout-restart:\(namespace):\(deploymentName)"
        case let .deletePod(podName, namespace):
            return "delete-pod:\(namespace):\(podName)"
        }
    }

    var title: String {
        switch self {
        case .scale:
            return "Scale 실행 전 확인"
        case .rolloutRestart:
            return "Rollout Restart 실행 전 확인"
        case .deletePod:
            return "Delete Pod 실행 전 확인"
        }
    }

    var summaryLines: [String] {
        switch self {
        case let .scale(deploymentName, namespace, fromReplicas, toReplicas):
            return [
                "Action: scale",
                "Resource: Deployment/\(deploymentName)",
                "Namespace: \(namespace)",
                "Requested replicas: \(toReplicas)",
                "Current replicas: \(fromReplicas)",
                "Rollback guidance: scale back to \(fromReplicas) replicas"
            ]
        case let .rolloutRestart(deploymentName, namespace):
            return [
                "Action: rollout-restart",
                "Resource: Deployment/\(deploymentName)",
                "Namespace: \(namespace)",
                "Rollback guidance: no direct undo, verify rollout status/events and apply known good rollout if needed"
            ]
        case let .deletePod(podName, namespace):
            return [
                "Action: delete-pod",
                "Resource: Pod/\(podName)",
                "Namespace: \(namespace)",
                "Impact: selected pod is deleted immediately",
                "Rollback guidance: controller-managed pods are recreated automatically; otherwise recreate manually"
            ]
        }
    }

    var confirmButtonTitle: String {
        switch self {
        case .scale:
            return "Scale 실행"
        case .rolloutRestart:
            return "Restart 실행"
        case .deletePod:
            return "Delete 실행"
        }
    }

    var buttonRole: ButtonRole? {
        switch self {
        case .deletePod:
            return .destructive
        case .scale, .rolloutRestart:
            return nil
        }
    }
}

private extension ViewModel.KubernetesActionResultState.Status {
    var displayText: String {
        switch self {
        case .success:
            return "Success"
        case .failure:
            return "Failure"
        case .cancelled:
            return "Cancelled"
        }
    }

    var displayColor: Color {
        switch self {
        case .success:
            return .green
        case .failure:
            return .red
        case .cancelled:
            return .orange
        }
    }
}

private extension String {
    var localizedAuditResult: String {
        switch self {
        case "success":
            return "Success"
        case "failure":
            return "Failure"
        case "cancelled":
            return "Cancelled"
        default:
            return self
        }
    }

    var auditResultColor: Color {
        switch self {
        case "success":
            return .green
        case "failure":
            return .red
        case "cancelled":
            return .orange
        default:
            return .secondary
        }
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
        .modelContainer(for: [KubernetesActionAuditEntry.self], inMemory: true)
}
