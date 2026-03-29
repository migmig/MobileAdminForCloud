import Foundation

struct KubernetesContextInfo: Equatable, Identifiable {
    let id: String
    let name: String

    init(name: String) {
        self.id = name
        self.name = name
    }
}

struct KubernetesNamespaceInfo: Equatable, Identifiable {
    let name: String
    var id: String { name }
}

struct KubernetesNamespaceListResponse: Codable {
    let items: [KubernetesNamespaceItem]
}

struct KubernetesNamespaceItem: Codable {
    let metadata: KubernetesObjectMetadata
}

struct KubernetesObjectMetadata: Codable {
    let name: String
}
