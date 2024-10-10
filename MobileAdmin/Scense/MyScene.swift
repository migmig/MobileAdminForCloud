//
//  MyScene.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

struct MyScene: Scene {
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                   .tabItem {
                       Label("ErrorList", systemImage: "person.crop.circle.badge.exclamationmark").onTapGesture {
                           print("ErrorList tapped")
                       }
                   } 
               SettingsView()
                   .tabItem {
                       Label("Settings", systemImage: "gear")
                   }
           }
        }
    }
}
  
