 
import SwiftUI


struct SettingsView: View {
    var body: some View {
        #if os(macOS)
        SettingsInTabView()
        #else
        SettingsInNavigationStack()
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
                SettingsDetailsView(title:item.rawValue)
                    .tabItem{
                        Label(item.rawValue, systemImage:item.image)
                    }
                    .tag(item)
            }
        }
        .frame(width:375,height:150)
    }
    
    //ios
    private func SettingsInNavigationStack() -> some View {
        NavigationStack{
            List{
                NavigationLink{
                    SettingsDetailsView(title:Settings.sync.rawValue)
                }label:{
                    Label(Settings.sync.rawValue, systemImage:Settings.sync.image)
                }
                
            }
            .navigationTitle("Settings")
        }
    }
} 
