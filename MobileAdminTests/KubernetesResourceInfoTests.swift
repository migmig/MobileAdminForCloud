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

    @Test func service_sorting_supportsNameAndAddressOptions() {
        let items = [
            KubernetesServiceInfo(name: "zeta", type: "ClusterIP", primaryAddress: "10.0.0.30", portCount: 1, externalAddress: nil),
            KubernetesServiceInfo(name: "alpha", type: "LoadBalancer", primaryAddress: "10.0.0.10", portCount: 2, externalAddress: "api.example.com")
        ]

        #expect(KubernetesServiceSortOption.nameAscending.sort(items).map(\.name) == ["alpha", "zeta"])
        #expect(KubernetesServiceSortOption.addressAscending.sort(items).map(\.name) == ["alpha", "zeta"])
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

    @Test func configMap_sorting_supportsNameAndKeyCountOptions() {
        let items = [
            KubernetesConfigMapInfo(name: "zeta", immutable: false, textData: ["A": "1"], textKeyNames: ["A"], binaryKeyNames: []),
            KubernetesConfigMapInfo(name: "alpha", immutable: false, textData: ["A": "1", "B": "2"], textKeyNames: ["A", "B"], binaryKeyNames: [])
        ]

        #expect(KubernetesConfigMapSortOption.nameAscending.sort(items).map(\.name) == ["alpha", "zeta"])
        #expect(KubernetesConfigMapSortOption.keyCountDescending.sort(items).map(\.name) == ["alpha", "zeta"])
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

    @Test func secret_copyableValue_requiresExplicitReveal() {
        let secret = KubernetesSecretInfo(
            name: "app-secret",
            type: "Opaque",
            immutable: false,
            keyNames: ["password"],
            encodedData: ["password": "cGFzcw=="]
        )

        #expect(secret.copyableValue(for: "password", isRevealed: false) == nil)
        #expect(secret.copyableValue(for: "password", isRevealed: true) == "pass")
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

    @Test func secret_sorting_supportsNameAndKeyCountOptions() {
        let items = [
            KubernetesSecretInfo(name: "zeta", type: "Opaque", immutable: false, keyNames: ["A"], encodedData: [:]),
            KubernetesSecretInfo(name: "alpha", type: "Opaque", immutable: false, keyNames: ["A", "B"], encodedData: [:])
        ]

        #expect(KubernetesSecretSortOption.nameAscending.sort(items).map(\.name) == ["alpha", "zeta"])
        #expect(KubernetesSecretSortOption.keyCountDescending.sort(items).map(\.name) == ["alpha", "zeta"])
    }
}
