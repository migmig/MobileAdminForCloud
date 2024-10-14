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
        MyScene()
        #elseif os(macOS)
        MyAlternativeScene()
        #endif
        
    }
} 