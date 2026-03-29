import Testing
@testable import MobileAdmin

struct KubernetesNavigationTests {
    @Test func developerTools_containsSourceKubernetes() {
        #expect(SlidebarItem.DeveloperTools.contains(.sourceKubernetes))
    }

    @Test func navigationState_kubernetesSelections_defaultNil() {
        let state = NavigationState()

        #expect(state.selectedKubePod == nil)
        #expect(state.selectedKubeDeployment == nil)
        #expect(state.selectedKubeService == nil)
        #expect(state.selectedKubeConfigMap == nil)
        #expect(state.selectedKubeSecret == nil)
    }

    @Test func navigationState_clearKubernetesSelections_clearsAllKubernetesSelections() {
        let state = NavigationState()
        state.selectedKubePod = KubernetesPodInfo(name: "api-123", phase: "Running", containerCount: 1, readyCount: 1)
        state.selectedKubeDeployment = KubernetesDeploymentInfo(name: "api", replicas: 3, readyReplicas: 3, availableReplicas: 3)
        state.selectedKubeService = KubernetesServiceInfo(name: "api", type: "ClusterIP", primaryAddress: "10.0.0.12", portCount: 1, externalAddress: nil)
        state.selectedKubeConfigMap = KubernetesConfigMapInfo(name: "app-config", immutable: false, textData: ["A": "1"], textKeyNames: ["A"], binaryKeyNames: [])
        state.selectedKubeSecret = KubernetesSecretInfo(name: "app-secret", type: "Opaque", immutable: false, keyNames: ["token"])

        state.clearKubernetesSelections()

        #expect(state.selectedKubePod == nil)
        #expect(state.selectedKubeDeployment == nil)
        #expect(state.selectedKubeService == nil)
        #expect(state.selectedKubeConfigMap == nil)
        #expect(state.selectedKubeSecret == nil)
    }
}
