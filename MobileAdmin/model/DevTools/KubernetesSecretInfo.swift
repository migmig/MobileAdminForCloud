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

    func matchesSearch(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return true }

        if name.localizedCaseInsensitiveContains(normalized) { return true }
        if type.localizedCaseInsensitiveContains(normalized) { return true }
        if keyNames.contains(where: { $0.localizedCaseInsensitiveContains(normalized) }) { return true }

        return false
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
