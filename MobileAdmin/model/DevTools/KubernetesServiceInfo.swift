import Foundation

struct KubernetesServiceInfo: Equatable, Identifiable {
    let name: String
    let type: String
    let primaryAddress: String
    let portCount: Int
    let externalAddress: String?

    var id: String { name }

    func matchesSearch(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return true }
        let fields = [name, type, primaryAddress, externalAddress ?? ""]
        return fields.contains { $0.localizedCaseInsensitiveContains(normalized) }
    }
}

enum KubernetesServiceSortOption: String, CaseIterable, Identifiable {
    case nameAscending
    case addressAscending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nameAscending:
            return "이름순"
        case .addressAscending:
            return "주소순"
        }
    }

    func sort(_ items: [KubernetesServiceInfo]) -> [KubernetesServiceInfo] {
        switch self {
        case .nameAscending:
            return items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .addressAscending:
            return items.sorted { $0.primaryAddress.localizedStandardCompare($1.primaryAddress) == .orderedAscending }
        }
    }
}

struct KubernetesServiceListResponse: Codable {
    let items: [KubernetesServiceItem]
}

struct KubernetesServiceItem: Codable {
    let metadata: KubernetesObjectMetadata
    let spec: KubernetesServiceSpec
    let status: KubernetesServiceStatus?
}

struct KubernetesServiceSpec: Codable {
    let type: String?
    let clusterIP: String?
    let clusterIPs: [String]?
    let externalName: String?
    let ports: [KubernetesServicePort]?
}

struct KubernetesServicePort: Codable {
    let name: String?
    let transportProtocol: String?
    let port: Int
    let targetPort: KubernetesTargetPort?
    let nodePort: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case transportProtocol = "protocol"
        case port
        case targetPort
        case nodePort
    }
}

enum KubernetesTargetPort: Codable, Equatable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

struct KubernetesServiceStatus: Codable {
    let loadBalancer: KubernetesLoadBalancerStatus?
}

struct KubernetesLoadBalancerStatus: Codable {
    let ingress: [KubernetesLoadBalancerIngress]?
}

struct KubernetesLoadBalancerIngress: Codable {
    let ip: String?
    let hostname: String?
}
