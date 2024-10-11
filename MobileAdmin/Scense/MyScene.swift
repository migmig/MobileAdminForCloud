//
//  MyScene.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

struct MyScene: Scene {
    @StateObject var viewModel = ViewModel()
    @State var toast:Toast? = Toast()
    @State private var isLoading: Bool = false
    var body: some Scene {
        WindowGroup {
            if isLoading{
                ProgressView("데이터 조회중")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            TabView {
                ContentView(viewModel:viewModel)
                   .tabItem {
                       Label("ErrorList", systemImage: "person.crop.circle.badge.exclamationmark").onTapGesture {
                           print("ErrorList tapped")
                       }
                   }
                ToastView(toastItem: $toast)
                    .tabItem{
                        Label("Toast", systemImage: "bell").onTapGesture {
                            print("Toast view tapped")
                        }
                    }
                    .onAppear()
                    {
                        Task{
                            isLoading = true;
                            await toast = viewModel.fetchToasts()
                            isLoading = false;
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
  
