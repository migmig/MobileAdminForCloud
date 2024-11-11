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
    @State var edcCrseCl:[EdcCrseCl] = []
    @State var selectedEdcCrseCl:EdcCrseCl = .init()
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
                    Label("오류", systemImage: "checkmark.message")
                }
                ToastView(
                    viewModel:viewModel,
                    toastManager: toastManager,
                    toastItem: $toast )
                .font(.custom("D2Coding", size: 16))
                .tabItem{
                    Label("토스트", systemImage: "bell")
                }
               
                EdcClsSidebarIOS( 
                    viewModel:viewModel
                )
                .font(.custom("D2Coding", size: 16))
                .tabItem{
                    Label("교육", systemImage: "book")
                } 
                GoodsListViewIOS(
                    viewModel:viewModel,
                    toastManager: toastManager,
                    goodsItems:$goodsItems
                )
                .font(.custom("D2Coding", size: 16))
                .tabItem {
                    Label("상품", systemImage: "cart")
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
