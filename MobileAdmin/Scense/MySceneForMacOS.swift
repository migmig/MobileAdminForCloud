 
import SwiftUI
import Logging

struct MySceneForMacOS: Scene {
    @StateObject private var viewModel = ViewModel()
    @AppStorage("serverType") var serverType:String = "local"
    let logger = Logger(label:"com.migmig.MobileAdmin.MySceneForMacOS")
    var body: some Scene {
        WindowGroup {
            ContentViewForMac(
                viewModel:viewModel
            )
            .onAppear{
                logger.info("serverType:\(serverType)")
                switch(serverType){
                case "local":
                    EnvironmentConfig.current = .local
                case "dev":
                    EnvironmentConfig.current = .development
                case "prod":
                    EnvironmentConfig.current = .production
                default:
#if DEBUG
                    EnvironmentConfig.current = .local
#else
                    EnvironmentConfig.current = .production
#endif
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
