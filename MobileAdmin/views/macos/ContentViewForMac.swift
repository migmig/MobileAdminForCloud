import SwiftUI

struct ContentViewForMac: View {
    @StateObject private var errorViewModel     = ErrorViewModel()
    @StateObject private var goodsViewModel     = GoodsViewModel()
    @StateObject private var codeViewModel      = CodeViewModel()
    @StateObject private var buildViewModel     = BuildViewModel()
    @StateObject private var pipelineViewModel  = PipelineViewModel()
    @StateObject private var commitViewModel    = CommitViewModel()
    @StateObject private var deployViewModel    = DeployViewModel()
    @StateObject private var educationViewModel = EducationViewModel()
    @StateObject private var toastViewModel     = ToastViewModel()
    @StateObject private var closeDeptViewModel = CloseDeptViewModel()
    @StateObject var navigationState: NavigationState = NavigationState()
    @ObservedObject var toastManager: ToastManager

    var body: some View {
        NavigationSplitView {
            SlidebarViewForMac(selection: $navigationState.selectedSidebarItem)
        } content: {
            ContentListViewForMac()
                .environmentObject(navigationState)
                .environmentObject(errorViewModel)
                .environmentObject(goodsViewModel)
                .environmentObject(codeViewModel)
                .environmentObject(buildViewModel)
                .environmentObject(pipelineViewModel)
                .environmentObject(commitViewModel)
                .environmentObject(deployViewModel)
                .environmentObject(educationViewModel)
                .environmentObject(toastViewModel)
                .environmentObject(closeDeptViewModel)
        } detail: {
            NavigationStack {
                DetailViewForMac()
                    .environmentObject(navigationState)
                    .environmentObject(toastManager)
                    .environmentObject(errorViewModel)
                    .environmentObject(codeViewModel)
                    .environmentObject(buildViewModel)
                    .environmentObject(pipelineViewModel)
                    .environmentObject(commitViewModel)
                    .environmentObject(deployViewModel)
                    .environmentObject(educationViewModel)
                    .environmentObject(toastViewModel)
            }
        }
    }
}


#Preview(
    traits: .fixedLayout(width: 1500, height: 1200)
){
    ContentViewForMac(
        toastManager: ToastManager()
    )
    .toolbar{
        ToolbarItem{
            Button(action: {
            }) {
                Label("새로고침", systemImage: "arrow.clockwise")
            }
        }
    }
}
