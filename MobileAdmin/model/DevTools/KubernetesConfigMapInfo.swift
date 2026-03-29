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

    func matchesSearch(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return true }

        if name.localizedCaseInsensitiveContains(normalized) { return true }
        if textKeyNames.contains(where: { $0.localizedCaseInsensitiveContains(normalized) }) { return true }
        if binaryKeyNames.contains(where: { $0.localizedCaseInsensitiveContains(normalized) }) { return true }
        if textData.values.contains(where: { $0.localizedCaseInsensitiveContains(normalized) }) { return true }

        return false
    }
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
