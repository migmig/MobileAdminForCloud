import Foundation

struct KubernetesDeploymentInfo: Equatable, Identifiable {
    let name: String
    let replicas: Int
    let readyReplicas: Int
    let availableReplicas: Int

    var id: String { name }
}

struct KubernetesDeploymentListResponse: Codable {
    let items: [KubernetesDeploymentItem]
}

struct KubernetesDeploymentItem: Codable {
    let metadata: KubernetesObjectMetadata
    let spec: KubernetesDeploymentSpec
    let status: KubernetesDeploymentStatus
}

struct KubernetesDeploymentSpec: Codable {
    let replicas: Int?
}

struct KubernetesDeploymentStatus: Codable {
    let readyReplicas: Int?
    let availableReplicas: Int?
}
