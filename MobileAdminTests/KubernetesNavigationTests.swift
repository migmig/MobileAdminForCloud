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
    }
}
