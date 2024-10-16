//
//  MyScene.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI
import Logging

struct MySceneForIOS: Scene {
    let logger = Logger(label:"com.migmig.MobileAdmin.MyScene")
    @StateObject private var viewModel = ViewModel()
    @State var toast:Toast? = Toast()
    @State private var isLoading: Bool = false
    var body: some Scene {
        WindowGroup {
            if isLoading{
                ProgressView("데이터 조회중")
                    .progressViewStyle(CircularProgressViewStyle())
            }
             
            
            TabView {
                ContentViewForIOS(viewModel:viewModel)
                   .tabItem {
                       Label("ErrorList", systemImage: "person.crop.circle.badge.exclamationmark").onTapGesture {
                           logger.info("ErrorList tapped")
                       }
                   }
                ToastView(
                    viewModel:viewModel,
                          toastItem: $toast)
                    .tabItem{
                        Label("Toast", systemImage: "bell").onTapGesture {
                            logger.info("Toast view tapped")
                        }
                    }
                    .onAppear()
                    {
                        Task{
                            logger.info("onAppear called")
                             
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
  
