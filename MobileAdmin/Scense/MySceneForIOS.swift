//
//  MyScene.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI
import Logging

struct MySceneForIOS: Scene {
    @StateObject private var toastManager: ToastManager = ToastManager()
    let logger = Logger(label:"com.migmig.MobileAdmin.MyScene")
    @AppStorage("serverType") var serverType:String = "local"
    @StateObject private var viewModel = ViewModel()
    @State var toast:Toast? = Toast(applcBeginDt: "", applcEndDt: "", noticeHder: "", noticeSj: "", noticeCn: "", useYn: "")
    @State private var isLoading: Bool = false
     
            
    var body: some Scene {
        WindowGroup {
            if isLoading{
                ZStack{
                    ProgressView("데이터 조회중")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
             
            
            TabView {
                ContentViewForIOS(viewModel:viewModel
                                  ,toastManager:toastManager)
                .font(.custom("D2Coding", size: 16))
                   .tabItem {
                       Label("ErrorList", systemImage: "person.crop.circle.badge.exclamationmark").onTapGesture {
                           logger.info("ErrorList tapped")
                       }
                   }
                ToastView(
                    viewModel:viewModel,
                    toastManager: toastManager,
                          toastItem: $toast)
                .font(.custom("D2Coding", size: 16))
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
            .toastManager(toastManager:toastManager)
            .onAppear{
                switch(serverType){
                case "local":
                    EnvironmentConfig.current = .local
                case "dev":
                    EnvironmentConfig.current = .development
                case "prod":
                    EnvironmentConfig.current = .production
                default:
#if DEBUG
                    EnvironmentConfig.current = .local
#else
                    EnvironmentConfig.current = .production
#endif
                }
            }
        }
    }
}
  
