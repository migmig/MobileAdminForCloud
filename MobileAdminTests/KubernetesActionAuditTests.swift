import Foundation
import Testing
@testable import MobileAdmin

struct KubernetesActionAuditTests {
    @Test func scale_entry_preserves_previous_and_requested_values() {
        let now = Date(timeIntervalSince1970: 1_735_680_000)
        let entry = KubernetesActionAuditEntry(
            timestamp: now,
            actionType: "scale",
            resourceKind: "deployment",
            resourceName: "api-server",
            namespace: "default",
            requestedValue: "5",
            previousValue: "3",
            result: "success",
            errorSummary: nil,
            rollbackGuidance: "kubectl scale deployment api-server --replicas=3 -n default",
            actorLabel: "macOS admin"
        )

        #expect(entry.timestamp == now)
        #expect(entry.actionType == "scale")
        #expect(entry.resourceKind == "deployment")
        #expect(entry.resourceName == "api-server")
        #expect(entry.namespace == "default")
        #expect(entry.requestedValue == "5")
        #expect(entry.previousValue == "3")
        #expect(entry.result == "success")
        #expect(entry.errorSummary == nil)
        #expect(entry.rollbackGuidance == "kubectl scale deployment api-server --replicas=3 -n default")
        #expect(entry.actorLabel == "macOS admin")
    }

    @Test func cancelled_result_is_recorded_without_error() {
        let entry = KubernetesActionAuditEntry(
            actionType: "restart",
            resourceKind: "deployment",
            resourceName: "worker",
            namespace: "ops",
            requestedValue: nil,
            previousValue: nil,
            result: "cancelled",
            errorSummary: nil,
            rollbackGuidance: nil,
            actorLabel: "macOS admin"
        )

        #expect(entry.result == "cancelled")
        #expect(entry.errorSummary == nil)
        #expect(entry.rollbackGuidance == nil)
    }

    @Test func scale_rollback_guidance_string_is_preserved_for_export() {
        let rollback = "kubectl scale deployment api-server --replicas=2 -n default"
        let entry = KubernetesActionAuditEntry(
            actionType: "scale",
            resourceKind: "deployment",
            resourceName: "api-server",
            namespace: "default",
            requestedValue: "4",
            previousValue: "2",
            result: "success",
            errorSummary: nil,
            rollbackGuidance: rollback,
            actorLabel: "macOS admin"
        )

        #expect(entry.rollbackGuidance == rollback)
    }
}
