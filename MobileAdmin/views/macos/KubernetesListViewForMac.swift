import SwiftUI

struct KubernetesListViewForMac: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var nav: NavigationState
    @State private var searchText: String = ""
    @State private var serviceSort: KubernetesServiceSortOption = .nameAscending
    @State private var configMapSort: KubernetesConfigMapSortOption = .nameAscending
    @State private var secretSort: KubernetesSecretSortOption = .nameAscending

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
        let items = searchText.isEmpty ? viewModel.kubeServices : viewModel.kubeServices.filter { $0.matchesSearch(searchText) }
        return serviceSort.sort(items)
    }

    private var filteredConfigMaps: [KubernetesConfigMapInfo] {
        let items = searchText.isEmpty ? viewModel.kubeConfigMaps : viewModel.kubeConfigMaps.filter { $0.matchesSearch(searchText) }
        return configMapSort.sort(items)
    }

    private var filteredSecrets: [KubernetesSecretInfo] {
        let items = searchText.isEmpty ? viewModel.kubeSecrets : viewModel.kubeSecrets.filter { $0.matchesSearch(searchText) }
        return secretSort.sort(items)
    }

    var body: some View {
        content
    }

    private var content: some View {
        List(selection: $nav.selectedKubePod) {
            contextSection
            namespaceSection
            sortSection
            podsSection
            deploymentsSection
            servicesSection
            configMapsSection
            secretsSection
        }
        .navigationTitle("Kubernetes")
        .searchable(text: $searchText, placement: .automatic, prompt: "리소스 이름, 타입, 키 검색")
        .task {
            await viewModel.refreshKubernetesOverview()
        }
        .onChange(of: viewModel.selectedKubeContext) { oldValue, newValue in
            guard oldValue != newValue, !newValue.isEmpty, !oldValue.isEmpty else { return }
            nav.clearKubernetesSelections()
            viewModel.clearSelectedKubernetesResources()
            Task { await viewModel.switchKubernetesContext(to: newValue) }
        }
        .onChange(of: viewModel.selectedKubeNamespace) { oldValue, newValue in
            guard oldValue != newValue, !newValue.isEmpty, !oldValue.isEmpty else { return }
            nav.clearKubernetesSelections()
            viewModel.clearSelectedKubernetesResources()
            Task { await viewModel.refreshKubernetesOverview() }
        }
        .onChange(of: nav.selectedKubePod) { _, newValue in
            nav.selectedKubeDeployment = nil
            nav.selectedKubeService = nil
            nav.selectedKubeConfigMap = nil
            nav.selectedKubeSecret = nil
            viewModel.clearSelectedKubernetesResources()
            viewModel.selectedKubePod = newValue
            Task {
                await viewModel.refreshPodLogs()
                await viewModel.loadSelectedPodOperationalDetails()
            }
        }
    }

    private var contextSection: some View {
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
    }

    private var namespaceSection: some View {
        Section("Namespace") {
            Picker("Namespace", selection: $viewModel.selectedKubeNamespace) {
                ForEach(viewModel.kubeNamespaces) { item in
                    Text(item.name).tag(item.name)
                }
            }
        }
    }

    private var sortSection: some View {
        Section("Sort") {
            Picker("Services", selection: $serviceSort) {
                ForEach(KubernetesServiceSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            Picker("ConfigMaps", selection: $configMapSort) {
                ForEach(KubernetesConfigMapSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            Picker("Secrets", selection: $secretSort) {
                ForEach(KubernetesSecretSortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        }
    }

    private var podsSection: some View {
        Section("Pods") {
            if filteredPods.isEmpty {
                EmptyStateView(systemImage: "shippingbox", title: "Pod가 없습니다")
                    .listRowBackground(Color.clear)
            }

            ForEach(filteredPods) { pod in
                NavigationLink(value: pod) {
                    KubernetesPodRow(pod: pod)
                }
            }
        }
    }

    private var deploymentsSection: some View {
        Section("Deployments") {
            if filteredDeployments.isEmpty {
                EmptyStateView(systemImage: "shippingbox.circle", title: "Deployment가 없습니다")
                    .listRowBackground(Color.clear)
            }

            ForEach(filteredDeployments) { deployment in
                Button {
                    nav.clearKubernetesSelections()
                    nav.selectedKubeDeployment = deployment
                    viewModel.clearSelectedKubernetesResources()
                    viewModel.selectedKubeDeployment = deployment
                    Task { await viewModel.loadSelectedDeploymentOperationalDetails() }
                } label: {
                    KubernetesDeploymentRow(deployment: deployment)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var servicesSection: some View {
        Section("Services") {
            if filteredServices.isEmpty {
                EmptyStateView(systemImage: "point.3.connected.trianglepath.dotted", title: "Service가 없습니다")
                    .listRowBackground(Color.clear)
            }

            ForEach(filteredServices) { service in
                Button {
                    nav.clearKubernetesSelections()
                    nav.selectedKubeService = service
                    viewModel.clearSelectedKubernetesResources()
                    viewModel.selectedKubeService = service
                    viewModel.resetKubernetesOperationalState()
                } label: {
                    KubernetesServiceRow(service: service)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var configMapsSection: some View {
        Section("ConfigMaps") {
            if filteredConfigMaps.isEmpty {
                EmptyStateView(systemImage: "doc.text", title: "ConfigMap이 없습니다")
                    .listRowBackground(Color.clear)
            }

            ForEach(filteredConfigMaps) { configMap in
                Button {
                    nav.clearKubernetesSelections()
                    nav.selectedKubeConfigMap = configMap
                    viewModel.clearSelectedKubernetesResources()
                    viewModel.selectedKubeConfigMap = configMap
                    viewModel.resetKubernetesOperationalState()
                } label: {
                    KubernetesConfigMapRow(configMap: configMap)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var secretsSection: some View {
        Section("Secrets") {
            if filteredSecrets.isEmpty {
                EmptyStateView(systemImage: "lock.doc", title: "Secret이 없습니다")
                    .listRowBackground(Color.clear)
            }

            ForEach(filteredSecrets) { secret in
                Button {
                    nav.clearKubernetesSelections()
                    nav.selectedKubeSecret = secret
                    viewModel.clearSelectedKubernetesResources()
                    viewModel.selectedKubeSecret = secret
                    viewModel.resetKubernetesOperationalState()
                } label: {
                    KubernetesSecretRow(secret: secret)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct KubernetesPodRow: View {
    let pod: KubernetesPodInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pod.name)
            Text(podStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var podStatusText: String {
        "\(pod.phase) · \(pod.readyCount)/\(pod.containerCount)"
    }
}

private struct KubernetesDeploymentRow: View {
    let deployment: KubernetesDeploymentInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deployment.name)
            Text("ready \(deployment.readyReplicas)/\(deployment.replicas)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct KubernetesServiceRow: View {
    let service: KubernetesServiceInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(service.name)
            Text(serviceSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var serviceSummary: String {
        "\(service.type) · \(service.primaryAddress) · ports \(service.portCount)"
    }
}

private struct KubernetesConfigMapRow: View {
    let configMap: KubernetesConfigMapInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(configMap.name)
            Text("text \(configMap.textKeyCount) · binary \(configMap.binaryKeyCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct KubernetesSecretRow: View {
    let secret: KubernetesSecretInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(secret.name)
            Text("\(secret.type) · keys \(secret.keyCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    KubernetesListViewForMac()
        .environmentObject(ViewModel())
        .environmentObject(NavigationState())
}
