
import SwiftUI
import Logging


struct SettingsView: View {
    @AppStorage("serverType") var serverType:String = "dev"
    let logger = Logger(label:"com.migmig.MobileAdmin.SettingsView")
    
    init(){
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
            EnvironmentConfig.current = .development
#else
            EnvironmentConfig.current = .production
#endif
        }
    }
    var body: some View {
#if os(macOS)
        SettingsInTabView( )
#else
        SettingsInNavigationStack( )
#endif
        
    }
    
    private enum Settings:String,CaseIterable{
        case sync = "ServerSetting"
        
        var image: String{
            switch self{
            case .sync:
                return "cloud"
            }
        }
    }
    
    //macos
    private func SettingsInTabView() -> some View {
        TabView{
            ForEach(Settings.allCases, id: \.self){ item in
                VStack{
                    SettingsDetailsView(title:item.rawValue )
                }
                .tabItem{
                    Label(item.rawValue, systemImage:item.image)
                }
                .tag(item)
            }
        }
        .frame(width:475,height:350)
    }
    
    //ios
    private func SettingsInNavigationStack() -> some View {
        VStack{
            SettingsDetailsView(title:Settings.sync.rawValue )
        }
        .padding()
        .navigationTitle(Settings.sync.rawValue) 
    }
}
