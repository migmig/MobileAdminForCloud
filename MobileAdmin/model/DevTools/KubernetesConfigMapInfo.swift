import Foundation

struct KubernetesConfigMapInfo: Equatable, Hashable, Identifiable {
    let name: String
    let immutable: Bool
    let textData: [String: String]
    let textKeyNames: [String]
    let binaryKeyNames: [String]

    var id: String { name }
    var textKeyCount: Int { textKeyNames.count }
    var binaryKeyCount: Int { binaryKeyNames.count }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

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

enum KubernetesConfigMapSortOption: String, CaseIterable, Identifiable {
    case nameAscending
    case keyCountDescending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nameAscending:
            return "이름순"
        case .keyCountDescending:
            return "키 개수순"
        }
    }

    func sort(_ items: [KubernetesConfigMapInfo]) -> [KubernetesConfigMapInfo] {
        switch self {
        case .nameAscending:
            return items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .keyCountDescending:
            return items.sorted {
                if $0.textKeyCount == $1.textKeyCount {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return $0.textKeyCount > $1.textKeyCount
            }
        }
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
