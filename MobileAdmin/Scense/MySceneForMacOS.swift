
import SwiftUI
import Logging
import SwiftData

struct MySceneForMacOS: Scene {
    @StateObject private var toastManager: ToastManager = ToastManager()
//    @StateObject private var viewModel = ViewModel()
    @AppStorage("serverType") var serverType:EnvironmentType = .local
    let logger = Logger(label:"com.migmig.MobileAdmin.MySceneForMacOS")
    @Query var allEnvironment: [EnvironmentModel]
  
    var body: some Scene {
        WindowGroup {
            if allEnvironment.count == 0 {
                EnvSetView(isPresented:.constant(false))
            }else{
                ContentViewForMac(
                    toastManager: toastManager
                )
                .toastManager(toastManager:toastManager)
                .onAppear{
                    print(allEnvironment)
                    EnvironmentConfig.initializeUrls(from: allEnvironment)
                    logger.info("serverType:\(serverType)")
                    EnvironmentConfig.current = serverType
                }
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
        //viewModel:ViewModel(),
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
