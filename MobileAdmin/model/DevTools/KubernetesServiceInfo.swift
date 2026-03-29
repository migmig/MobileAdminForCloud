import Foundation

struct KubernetesServiceInfo: Equatable, Identifiable {
    let name: String
    let type: String
    let primaryAddress: String
    let portCount: Int
    let externalAddress: String?

    var id: String { name }
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
