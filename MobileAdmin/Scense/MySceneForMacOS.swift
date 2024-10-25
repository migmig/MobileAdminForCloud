
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
//               switch(serverType){
//               case "local":
//                   EnvironmentConfig.current = .local
//               case "dev":
//                   EnvironmentConfig.current = .development
//               case "prod":
//                   EnvironmentConfig.current = .production
//               default:
//#if DEBUG
//                   EnvironmentConfig.current = .local
//#else
//                   EnvironmentConfig.current = .production
//#endif
//               }
           }
       }
       
       #if os(macOS)
       Settings {
           SettingsView()
       }
       #endif
   }
}
