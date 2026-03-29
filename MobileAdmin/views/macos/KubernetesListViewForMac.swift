import SwiftUI

struct KubernetesListViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState
    @State private var searchText: String = ""

    private var filteredPods: [KubernetesPodInfo] {
        if searchText.isEmpty { return viewModel.kubePods }
        return viewModel.kubePods.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.phase.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredDeployments: [KubernetesDeploymentInfo] {
        if searchText.isEmpty { return viewModel.kubeDeployments }
        return viewModel.kubeDeployments.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredServices: [KubernetesServiceInfo] {
        if searchText.isEmpty { return viewModel.kubeServices }
        return viewModel.kubeServices.filter { $0.matchesSearch(searchText) }
    }

    private var filteredConfigMaps: [KubernetesConfigMapInfo] {
        if searchText.isEmpty { return viewModel.kubeConfigMaps }
        return viewModel.kubeConfigMaps.filter { $0.matchesSearch(searchText) }
    }

    private var filteredSecrets: [KubernetesSecretInfo] {
        if searchText.isEmpty { return viewModel.kubeSecrets }
        return viewModel.kubeSecrets.filter { $0.matchesSearch(searchText) }
    }

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
                if filteredPods.isEmpty {
                    EmptyStateView(systemImage: "shippingbox", title: "Pod가 없습니다")
                        .listRowBackground(Color.clear)
                }

                ForEach(filteredPods) { pod in
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
                if filteredDeployments.isEmpty {
                    EmptyStateView(systemImage: "shippingbox.circle", title: "Deployment가 없습니다")
                        .listRowBackground(Color.clear)
                }

                ForEach(filteredDeployments) { deployment in
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

            Section("Services") {
                if filteredServices.isEmpty {
                    EmptyStateView(systemImage: "point.3.connected.trianglepath.dotted", title: "Service가 없습니다")
                        .listRowBackground(Color.clear)
                }

                ForEach(filteredServices) { service in
                    Button {
                        nav.selectedKubeService = service
                        viewModel.selectedKubeService = service
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.name)
                            Text("\(service.type) · \(service.primaryAddress) · ports \(service.portCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("ConfigMaps") {
                if filteredConfigMaps.isEmpty {
                    EmptyStateView(systemImage: "doc.text", title: "ConfigMap이 없습니다")
                        .listRowBackground(Color.clear)
                }

                ForEach(filteredConfigMaps) { configMap in
                    Button {
                        nav.selectedKubeConfigMap = configMap
                        viewModel.selectedKubeConfigMap = configMap
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(configMap.name)
                            Text("text \(configMap.textKeyCount) · binary \(configMap.binaryKeyCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Secrets") {
                if filteredSecrets.isEmpty {
                    EmptyStateView(systemImage: "lock.doc", title: "Secret이 없습니다")
                        .listRowBackground(Color.clear)
                }

                ForEach(filteredSecrets) { secret in
                    Button {
                        nav.selectedKubeSecret = secret
                        viewModel.selectedKubeSecret = secret
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(secret.name)
                            Text("\(secret.type) · keys \(secret.keyCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Kubernetes")
        .searchable(text: $searchText, placement: .automatic, prompt: "리소스 이름, 타입, 키 검색")
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
