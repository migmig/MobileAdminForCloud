//
//  MyAlternativeScene.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//


/*
See LICENSE folder for this sample’s licensing information.
*/

import SwiftUI

struct MyAlternativeScene: Scene {
    var body: some Scene {
        WindowGroup {
            AlternativeContentView()
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
