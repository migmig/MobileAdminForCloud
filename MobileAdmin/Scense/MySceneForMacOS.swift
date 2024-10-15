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

struct MySceneForMacOS: Scene {
    @StateObject private var viewModel = ViewModel()
    var body: some Scene {
        WindowGroup {
            ContentViewForMac(
                viewModel:viewModel
            )
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
