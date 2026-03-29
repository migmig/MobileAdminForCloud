import SwiftUI

struct KubernetesDetailViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState
    @State private var replicaCount: Int = 1
    @State private var showDeleteConfirmation = false

    var body: some View {
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
    }
}

#Preview {
    KubernetesDetailViewForMac()
        .environmentObject(ViewModel())
        .environmentObject(NavigationState())
}
