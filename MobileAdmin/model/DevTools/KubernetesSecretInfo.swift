import Foundation

struct KubernetesSecretInfo: Equatable, Identifiable {
    let name: String
    let type: String
    let immutable: Bool
    let keyNames: [String]

    var id: String { name }
    var keyCount: Int { keyNames.count }
}

struct KubernetesSecretListResponse: Codable {
    let items: [KubernetesSecretItem]
}

struct KubernetesSecretItem: Codable {
    let metadata: KubernetesObjectMetadata
    let type: String?
    let immutable: Bool?
    let data: [String: String]?
}
