//
//  MobileAdminApp.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

@main
struct MobileAdminApp: App {
    
    
    var body: some Scene {
        #if os(iOS)
        MySceneForIOS()
        #elseif os(macOS)
        MySceneForMacOS()
        #endif
        
    }
}
#if os(iOS)
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
