
import SwiftUI
import Logging

struct MySceneForMacOS: Scene {
    @StateObject private var toastManager: ToastManager = ToastManager()
    @StateObject private var viewModel = ViewModel()
    @AppStorage("serverType") var serverType:EnvironmentType = .local
    let logger = Logger(label:"com.migmig.MobileAdmin.MySceneForMacOS")
    var body: some Scene {
        WindowGroup {
            ContentViewForMac(
                viewModel:viewModel,
                toastManager: toastManager
            )
            .toastManager(toastManager:toastManager)
            .onAppear{
                logger.info("serverType:\(serverType)")
                EnvironmentConfig.current = serverType
            }
        }
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#Preview(
    traits: .fixedLayout(width: 1500, height: 1200)
){
    
    ContentViewForMac(
        viewModel:ViewModel(),
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
