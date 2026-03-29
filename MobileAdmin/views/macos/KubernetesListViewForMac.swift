import SwiftUI

struct KubernetesListViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState

    var body: some View {
        List(selection: $nav.selectedKubePod) {
            Section("Context") {
                HStack {
                    Circle()
                        .fill(viewModel.isKubectlAvailable ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isKubectlAvailable ? "kubectl 사용 가능" : "kubectl 사용 불가")
                }

                Picker("Context", selection: $viewModel.selectedKubeContext) {
                    ForEach(viewModel.kubeContexts) { item in
                        Text(item.name).tag(item.name)
                    }
                }
            }

            Section("Namespace") {
                Picker("Namespace", selection: $viewModel.selectedKubeNamespace) {
                    ForEach(viewModel.kubeNamespaces) { item in
                        Text(item.name).tag(item.name)
                    }
                }
            }

            Section("Pods") {
                if viewModel.kubePods.isEmpty {
                    EmptyStateView(systemImage: "shippingbox", title: "Pod가 없습니다")
                        .listRowBackground(Color.clear)
                }

                ForEach(viewModel.kubePods) { pod in
                    NavigationLink(value: pod) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pod.name)
                            Text("\(pod.phase) · \(pod.readyCount)/\(pod.containerCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Deployments") {
                if viewModel.kubeDeployments.isEmpty {
                    EmptyStateView(systemImage: "shippingbox.circle", title: "Deployment가 없습니다")
                        .listRowBackground(Color.clear)
                }

                ForEach(viewModel.kubeDeployments) { deployment in
                    Button {
                        nav.selectedKubeDeployment = deployment
                        viewModel.selectedKubeDeployment = deployment
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deployment.name)
                            Text("ready \(deployment.readyReplicas)/\(deployment.replicas)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Kubernetes")
        .task {
            await viewModel.refreshKubernetesOverview()
        }
        .onChange(of: viewModel.selectedKubeContext) { oldValue, newValue in
            guard oldValue != newValue, !newValue.isEmpty, !oldValue.isEmpty else { return }
            Task { await viewModel.switchKubernetesContext(to: newValue) }
        }
        .onChange(of: viewModel.selectedKubeNamespace) { oldValue, newValue in
            guard oldValue != newValue, !newValue.isEmpty, !oldValue.isEmpty else { return }
            Task { await viewModel.refreshKubernetesOverview() }
        }
        .onChange(of: nav.selectedKubePod) { _, newValue in
            viewModel.selectedKubePod = newValue
            Task { await viewModel.refreshPodLogs() }
        }
    }
}

#Preview {
    KubernetesListViewForMac()
        .environmentObject(ViewModel())
        .environmentObject(NavigationState())
}
