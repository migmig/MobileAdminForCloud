import Foundation
import SwiftData

@Model
class KubernetesActionAuditEntry {
    var timestamp: Date
    var actionType: String
    var resourceKind: String
    var resourceName: String
    var namespace: String
    var requestedValue: String?
    var previousValue: String?
    var result: String
    var errorSummary: String?
    var rollbackGuidance: String?
    var actorLabel: String

    init(
        timestamp: Date = .now,
        actionType: String,
        resourceKind: String,
        resourceName: String,
        namespace: String,
        requestedValue: String? = nil,
        previousValue: String? = nil,
        result: String,
        errorSummary: String? = nil,
        rollbackGuidance: String? = nil,
        actorLabel: String
    ) {
        self.timestamp = timestamp
        self.actionType = actionType
        self.resourceKind = resourceKind
        self.resourceName = resourceName
        self.namespace = namespace
        self.requestedValue = requestedValue
        self.previousValue = previousValue
        self.result = result
        self.errorSummary = errorSummary
        self.rollbackGuidance = rollbackGuidance
        self.actorLabel = actorLabel
    }
}
