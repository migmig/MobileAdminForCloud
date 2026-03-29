import Foundation

struct KubernetesSecretInfo: Equatable, Identifiable {
    let name: String
    let type: String
    let immutable: Bool
    let keyNames: [String]
    let encodedData: [String: String]

    var id: String { name }
    var keyCount: Int { keyNames.count }

    init(
        name: String,
        type: String,
        immutable: Bool,
        keyNames: [String],
        encodedData: [String: String] = [:]
    ) {
        self.name = name
        self.type = type
        self.immutable = immutable
        self.keyNames = keyNames
        self.encodedData = encodedData
    }

    func decodedValue(for key: String) -> String? {
        guard let encodedValue = encodedData[key],
              let data = Data(base64Encoded: encodedValue),
              let stringValue = String(data: data, encoding: .utf8) else {
            return nil
        }

        return stringValue
    }

    func copyableValue(for key: String, isRevealed: Bool) -> String? {
        guard isRevealed else { return nil }
        return decodedValue(for: key)
    }

    func matchesSearch(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return true }

        if name.localizedCaseInsensitiveContains(normalized) { return true }
        if type.localizedCaseInsensitiveContains(normalized) { return true }
        if keyNames.contains(where: { $0.localizedCaseInsensitiveContains(normalized) }) { return true }

        return false
    }
}

enum KubernetesSecretSortOption: String, CaseIterable, Identifiable {
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

    func sort(_ items: [KubernetesSecretInfo]) -> [KubernetesSecretInfo] {
        switch self {
        case .nameAscending:
            return items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .keyCountDescending:
            return items.sorted {
                if $0.keyCount == $1.keyCount {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return $0.keyCount > $1.keyCount
            }
        }
    }
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
