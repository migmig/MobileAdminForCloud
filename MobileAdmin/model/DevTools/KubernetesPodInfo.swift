import Foundation

struct KubernetesPodInfo: Equatable, Hashable, Identifiable {
    let name: String
    let phase: String
    let containerCount: Int
    let readyCount: Int

    var id: String { name }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct KubernetesPodListResponse: Codable {
    let items: [KubernetesPodItem]
}

struct KubernetesPodItem: Codable {
    let metadata: KubernetesObjectMetadata
    let spec: KubernetesPodSpec
    let status: KubernetesPodStatus
}

struct KubernetesPodSpec: Codable {
    let containers: [KubernetesNamedContainer]
}

struct KubernetesNamedContainer: Codable {
    let name: String
}

struct KubernetesPodStatus: Codable {
    let phase: String
    let containerStatuses: [KubernetesContainerStatus]?
}

struct KubernetesContainerStatus: Codable {
    let ready: Bool
}
