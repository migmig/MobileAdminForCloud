
import SwiftUI
import Logging
import SwiftData
import LocalAuthentication

struct MySceneForIOS: Scene {
   let logger = Logger(label:"com.migmig.MobileAdmin.MyScene")
   @AppStorage("serverType") var serverType:EnvironmentType = .local
   // 도메인별 ViewModel (각자 필요한 상태만 관리)
   @StateObject private var errorViewModel     = ErrorViewModel()
   @StateObject private var goodsViewModel     = GoodsViewModel()
   @StateObject private var codeViewModel      = CodeViewModel()
   @StateObject private var buildViewModel     = BuildViewModel()
   @StateObject private var pipelineViewModel  = PipelineViewModel()
   @StateObject private var commitViewModel    = CommitViewModel()
   @StateObject private var deployViewModel    = DeployViewModel()
   @StateObject private var educationViewModel = EducationViewModel()
   @StateObject private var toastViewModel     = ToastViewModel()
   @StateObject private var closeDeptViewModel = CloseDeptViewModel()

   @State private var selectedTab: Int = 0
   @State private var isAuthenticated = false
   @State private var authenticationMessage = ""
   @Query var allEnvironment: [EnvironmentModel]

   var body: some Scene {
       WindowGroup {
           if allEnvironment.count == 0 {
               EnvSetView(isPresented:.constant(false))
           }else{
               if !isAuthenticated {
                   VStack(spacing: AppSpacing.xl) {
                       Spacer()

                       Image(systemName: "lock.shield")
                           .font(.system(size: 56))
                           .foregroundStyle(.secondary)

                       VStack(spacing: AppSpacing.sm) {
                           Text("인증이 필요합니다")
                               .font(.title2)
                               .fontWeight(.bold)
                           Text("생체 인증으로 앱에 접근하세요")
                               .font(AppFont.caption)
                               .foregroundColor(.secondary)
                       }

                       Button(action: authenticateUser) {
                           Label("생체 인증 시도", systemImage: "faceid")
                               .fontWeight(.semibold)
                               .frame(maxWidth: 240)
                               .padding(.vertical, AppSpacing.md)
                       }
                       .buttonStyle(.borderedProminent)
                       .controlSize(.large)

                       if !authenticationMessage.isEmpty {
                           Text(authenticationMessage)
                               .font(AppFont.caption)
                               .foregroundColor(.red)
                               .padding(.horizontal, AppSpacing.xl)
                       }

                       Spacer()
                   }
                   .frame(maxWidth: .infinity, maxHeight: .infinity)
                   .onAppear(){
                       authenticateUser()
                   }
               }else{
                   let tabItems: [(Int, String, String, AnyView)] = [
                       (0, "홈",      "house.fill",                     AnyView(HomeViewForIOS())),
                       (1, "개시마감", SlidebarItem.closeDeptList.img,  AnyView(CloseDeptListViewIOS())),
                       (2, "개발도구", "wrench.and.screwdriver.fill",   AnyView(SourceControlViewForIOS())),
                       (3, "설정",     "gearshape.fill",                AnyView(SettingsView()))
                   ]
                   
                   
                       TabView(selection: $selectedTab) {
                           ForEach(tabItems, id: \.0) { tabItem in
                               tabItem.3
                                   .tabItem {
                                       Label(tabItem.1, systemImage: tabItem.2)
                                   }
                                   .tag(tabItem.0)
                                   .environmentObject(errorViewModel)
                                   .environmentObject(goodsViewModel)
                                   .environmentObject(codeViewModel)
                                   .environmentObject(buildViewModel)
                                   .environmentObject(pipelineViewModel)
                                   .environmentObject(commitViewModel)
                                   .environmentObject(deployViewModel)
                                   .environmentObject(educationViewModel)
                                   .environmentObject(toastViewModel)
                                   .environmentObject(closeDeptViewModel)
                           }
                       }
                       .ignoresSafeArea()
                   .onAppear{
                       logger.debug("\(allEnvironment)")
                       EnvironmentConfig.initializeUrls(from: allEnvironment)
                       logger.info("serverType:\(serverType)")
                       EnvironmentConfig.current = serverType
                   }
                   .onChange(of: selectedTab){oldValue,newValue in
                       withAnimation(.easeInOut(duration: 0.5)) {
                           selectedTab = newValue
                           logger.debug("tab changed: \(newValue)")
                           logger.debug("selectedTab: \(selectedTab)")
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
                       self.authenticationMessage = ""
                   } else {
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
