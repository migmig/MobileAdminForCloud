//
//  ContentView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI


struct SettingsView: View {
    var body: some View {
        #if os(macOS)
        SettingsInTabView()
        #else
        SettingsInNavigationStack()
        #endif
    }
    
    private func SettingsInTabView() -> some View {
        TabView {
             
        }
    }
    
    private func SettingsInNavigationStack() -> some View {
        NavigationView {
            Text("dd")
        }
    }
}
 
