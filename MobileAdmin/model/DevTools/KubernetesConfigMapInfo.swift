import Foundation

struct KubernetesConfigMapInfo: Equatable, Identifiable {
    let name: String
    let immutable: Bool
    let textData: [String: String]
    let textKeyNames: [String]
    let binaryKeyNames: [String]

    var id: String { name }
    var textKeyCount: Int { textKeyNames.count }
    var binaryKeyCount: Int { binaryKeyNames.count }
}

struct KubernetesConfigMapListResponse: Codable {
    let items: [KubernetesConfigMapItem]
}

struct KubernetesConfigMapItem: Codable {
    let metadata: KubernetesObjectMetadata
    let immutable: Bool?
    let data: [String: String]?
    let binaryData: [String: String]?
}
