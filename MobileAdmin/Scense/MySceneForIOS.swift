//
//  MyScene.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI
import Logging
import SwiftData

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
    @State private var selectedTab: Int = 0 // 현재 선택된 탭
    @Query var allEnvironment: [EnvironmentModel]
 
    var body: some Scene {
        WindowGroup {
            if allEnvironment.count == 0 {
                EnvSetView(isPresented:.constant(false))
            }else{
                let tabItems: [(Int, String, String, AnyView)] = [
                    (0, "오류"    , "checkmark.message" , AnyView(ErrorListViewForIOS(viewModel: viewModel, toastManager: toastManager))),
                    (1, "토스트"  , "bell"              , AnyView(ToastView(viewModel: viewModel, toastManager: toastManager, toastItem: $toast))),
                    (2, "개시여부", "square.and.pencil" , AnyView(CloseDeptListViewIOS(viewModel: viewModel))),
                    (3, "상품"    , "cart"              , AnyView(GoodsListViewIOS(viewModel: viewModel, toastManager: toastManager, goodsItems: $goodsItems))),
                    (4, "코드"    , "list.bullet"       , AnyView(CodeListViewIOS(viewModel: viewModel))),
                    (5, "교육"    , "book"              , AnyView(EdcClsSidebarIOS(viewModel: viewModel))),
                    (6, "Settings", "gear"              , AnyView(SettingsView()))
                ]

                TabView(selection: $selectedTab) {
                    ForEach(tabItems, id: \.0) { tabItem in
                        tabItem.3
                            .font(.custom("D2Coding", size: 16))
                            .tabItem {
                                Label(tabItem.1, systemImage: tabItem.2)
                            }
                            .tag(tabItem.0)
                    }
                }
 
                .toastManager(toastManager:toastManager)
                .onAppear{
                    print(allEnvironment)
                    EnvironmentConfig.initializeUrls(from: allEnvironment)
                    logger.info("serverType:\(serverType)")
                    EnvironmentConfig.current = serverType
                }
                .onChange(of: selectedTab){oldValue,newValue in
                    withAnimation(.spring()){
                        selectedTab = newValue
                        print(newValue)
                        print(selectedTab)
                    }
                }
            }
        }
    }
}
 
#Preview{
    
        EnvSetView(isPresented:.constant(false))
}
