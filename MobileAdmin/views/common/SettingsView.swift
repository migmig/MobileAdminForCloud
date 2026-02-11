
import SwiftUI

struct SettingsView: View {
    @AppStorage("serverType") var serverType:EnvironmentType = .development
    
    init(){
        EnvironmentConfig.current = serverType
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
                    Label(item.rawValue, systemImage: item.image)
                }
                .tag(item)
            }
        }
    }
    
    //ios
    private func SettingsInNavigationStack() -> some View {
        VStack{
            SettingsDetailsView(title:Settings.sync.rawValue )
        }
        .navigationTitle(Settings.sync.rawValue)
    }
}

#Preview {
    SettingsView()
}
