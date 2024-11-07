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
    @StateObject private var toastManager: ToastManager = ToastManager()
    @AppStorage("serverType") var serverType:EnvironmentType = .local
    @StateObject private var viewModel = ViewModel()
    @State var toast:Toast = Toast(applcBeginDt: nil, applcEndDt: nil, noticeHder: "", noticeSj: "", noticeCn: "", useYn: "")
    @State var goodsItems:[Goodsinfo] = []
    @State private var isLoading: Bool = false
    
    var body: some Scene {
        WindowGroup {
            TabView {
                if isLoading{
                    ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
                }
                ErrorListViewForIOS(viewModel:viewModel
                                    ,toastManager:toastManager)
                .font(.custom("D2Coding", size: 16))
                .tabItem {
                    Label("ErrorList", systemImage: "checkmark.message")
                }
                ToastView(
                    viewModel:viewModel,
                    toastManager: toastManager,
                    toastItem: $toast )
                .font(.custom("D2Coding", size: 16))
                .tabItem{
                    Label("Toast", systemImage: "bell")
                }
//                .onAppear()
//                {
//                    Task{
//                        //logger.info("onAppear called")
//                        
//                        isLoading = true;
//                        await toast = viewModel.fetchToasts()
//                        isLoading = false;
//                    }
//                }
                GoodsListViewIOS(
                    viewModel:viewModel,
                    toastManager: toastManager,
                    goodsItems:$goodsItems
                )
                .font(.custom("D2Coding", size: 16))
                .tabItem {
                    Label("GoodsInfo", systemImage: "cart")
                }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .toastManager(toastManager:toastManager)
            .onAppear{
                logger.info("serverType:\(serverType)")
                EnvironmentConfig.current = serverType 
            }
        }
    }
}

