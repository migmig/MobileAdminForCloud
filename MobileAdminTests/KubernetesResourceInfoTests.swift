import Testing
@testable import MobileAdmin

struct KubernetesResourceInfoTests {
    @Test func service_matchesSearch_onNameTypeAndAddress() {
        let service = KubernetesServiceInfo(
            name: "api-service",
            type: "ClusterIP",
            primaryAddress: "10.0.0.12",
            portCount: 2,
            externalAddress: "api.example.com"
        )

        #expect(service.matchesSearch("api"))
        #expect(service.matchesSearch("clusterip"))
        #expect(service.matchesSearch("10.0.0"))
        #expect(service.matchesSearch("example.com"))
        #expect(service.matchesSearch("worker") == false)
    }

    @Test func configMap_matchesSearch_onNameAndKeys() {
        let configMap = KubernetesConfigMapInfo(
            name: "app-config",
            immutable: false,
            textData: ["SPRING_PROFILE": "prod"],
            textKeyNames: ["SPRING_PROFILE"],
            binaryKeyNames: ["cert.pem"]
        )

        #expect(configMap.matchesSearch("app"))
        #expect(configMap.matchesSearch("spring_profile"))
        #expect(configMap.matchesSearch("cert"))
        #expect(configMap.matchesSearch("missing") == false)
    }

    @Test func secret_decodedValue_returnsUTF8StringForExplicitReveal() {
        let secret = KubernetesSecretInfo(
            name: "app-secret",
            type: "Opaque",
            immutable: false,
            keyNames: ["password"],
            encodedData: ["password": "cGFzcw=="]
        )

        #expect(secret.decodedValue(for: "password") == "pass")
        #expect(secret.decodedValue(for: "missing") == nil)
    }

    @Test func secret_matchesSearch_usesMetadataAndKeysButNotDecodedValues() {
        let secret = KubernetesSecretInfo(
            name: "app-secret",
            type: "Opaque",
            immutable: false,
            keyNames: ["password"],
            encodedData: ["password": "cGFzcw=="]
        )

        #expect(secret.matchesSearch("app-secret"))
        #expect(secret.matchesSearch("opaque"))
        #expect(secret.matchesSearch("password"))
        #expect(secret.matchesSearch("pass") == false)
    }
}
