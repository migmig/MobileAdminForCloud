
import SwiftUI
import Logging
import SwiftData
import LocalAuthentication

struct MySceneForIOS: Scene {
   let logger = Logger(label:"com.migmig.MobileAdmin.MyScene")
  // @StateObject private var toastManager: ToastManager = ToastManager()
   @AppStorage("serverType") var serverType:EnvironmentType = .local
   //@StateObject private var viewModel = ViewModel()
   @State var toast:Toast = Toast(applcBeginDt: nil, applcEndDt: nil, noticeHder: "", noticeSj: "", noticeCn: "", useYn: "")
//    @State var goodsItems:[Goodsinfo] = []
   @State var edcCrseCl:[EdcCrseCl] = []
   @State var selectedEdcCrseCl:EdcCrseCl = .init()
   @State private var isLoading: Bool = false
   @State private var selectedTab: Int = 0 // 현재 선택된 탭
   @State private var isAuthenticated = true
   @State private var authenticationMessage = ""
   @Query var allEnvironment: [EnvironmentModel]

   var body: some Scene {
       WindowGroup {
           if allEnvironment.count == 0 {
               EnvSetView(isPresented:.constant(false))
           }else{
               if !isAuthenticated {
                   VStack {
                       if isAuthenticated {
                           Text("🎉 인증 성공!")
                               .font(.largeTitle)
                               .padding()
                       } else {
                           Text("🔒 잠긴 상태")
                               .font(.largeTitle)
                               .padding()
                           Button(action: authenticateUser) {
                               Text("생체 인증 시도")
                                   .padding()
                                   .background(Color.blue)
                                   .foregroundColor(.white)
                                   .cornerRadius(10)
                           }
                           .padding()
                           
                           if !authenticationMessage.isEmpty {
                               Text(authenticationMessage)
                                   .foregroundColor(.red)
                                   .padding()
                           }
                       }
                   }
                   .padding()
                   .onAppear(){
                       authenticateUser()
                   }
               }else{
                   let tabItems: [(UUID, String, String, AnyView)] = [
                       (UUID() ,"홈"                            ,"house"                          ,AnyView(HomeViewForIOS())),
                       (UUID(), SlidebarItem.toast.title        , SlidebarItem.toast.img         , AnyView(ToastView(toastItem: $toast))),
                       (UUID(), SlidebarItem.closeDeptList.title, SlidebarItem.closeDeptList.img , AnyView(CloseDeptListViewIOS())),
                       (UUID(), "개발도구"                      , "hammer"                       , AnyView(SourceControlViewForIOS())),
                       (UUID(), "환경설정"                      , "gear"                         , AnyView(SettingsView()))
                   ]
                   
                   TabView(selection: $selectedTab) {
                       ForEach(tabItems, id: \.0) { tabItem in
                           tabItem.3
                               .tabItem {
                                   Label(tabItem.1, systemImage: tabItem.2)
                               }
                               .tag(tabItem.0)
                       }
                   }
                   .ignoresSafeArea()
                   
                  // .toastManager(toastManager:toastManager)
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
   
   
   func authenticateUser() {
       let context = LAContext()
       var error: NSError?
       
       // 생체 인증 가능 여부 확인
       if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
           let reason = "앱에 접근하기 위해 생체 인증이 필요합니다."
           
           context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
               DispatchQueue.main.async {
                   if success {
                       self.isAuthenticated = true
                       self.authenticationMessage = "인증에 성공했습니다!"
                   } else {
                       self.isAuthenticated = false
                       self.authenticationMessage = "인증에 실패했습니다."
                   }
               }
           }
       } else {
           // 생체 인증이 지원되지 않는 경우
           DispatchQueue.main.async {
               self.authenticationMessage = "생체 인증을 사용할 수 없습니다."
           }
       }
   }
}

#Preview{
    
        let tabItems: [(UUID, String, String, AnyView)] = [
            (UUID() ,"홈"                            ,"house"                          ,AnyView(HomeViewForIOS())),
            (UUID(), SlidebarItem.closeDeptList.title, SlidebarItem.closeDeptList.img , AnyView(CloseDeptListViewIOS())),
            (UUID(), "개발도구"                      , "hammer"                       , AnyView(SourceControlViewForIOS())),
            (UUID(), "환경설정"                      , "gear"                         , AnyView(SettingsView()))
        ]
        
        TabView() {
            ForEach(tabItems, id: \.0) { tabItem in
                tabItem.3
                    .tabItem {
                        Label(tabItem.1, systemImage: tabItem.2)
                    }
                    .tag(tabItem.0)
            }
        } 
}
