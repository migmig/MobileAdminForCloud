import SwiftUI

struct ContentViewForMac: View {
    @StateObject var viewModel: ViewModel = ViewModel()
    @StateObject var navigationState: NavigationState = NavigationState()
    @ObservedObject var toastManager: ToastManager

    var body: some View {
        NavigationSplitView {
            SlidebarViewForMac(selection: $navigationState.selectedSidebarItem)
        } content: {
            ContentListViewForMac()
                .environmentObject(viewModel)
                .environmentObject(navigationState)
        } detail: {
            NavigationStack {
                DetailViewForMac()
                    .environmentObject(viewModel)
                    .environmentObject(navigationState)
                    .environmentObject(toastManager)
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
