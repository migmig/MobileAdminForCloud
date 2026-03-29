import Foundation

struct KubernetesEventInfo: Equatable, Hashable, Identifiable {
    let type: String
    let reason: String
    let message: String
    let involvedKind: String
    let involvedName: String
    let timestampText: String

    var id: String { [involvedKind, involvedName, reason, timestampText, message].joined(separator: ":") }
}

struct KubernetesEventListResponse: Codable {
    let items: [KubernetesEventItem]
}

struct KubernetesEventItem: Codable {
    let type: String?
    let reason: String?
    let message: String?
    let eventTime: String?
    let lastTimestamp: String?
    let firstTimestamp: String?
    let involvedObject: KubernetesEventInvolvedObject
}

struct KubernetesEventInvolvedObject: Codable {
    let kind: String?
    let name: String?
}
