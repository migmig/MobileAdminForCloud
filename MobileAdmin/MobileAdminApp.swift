//
//  MobileAdminApp.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//



import SwiftUI
import SwiftData
import LocalAuthentication
import Foundation
import Logging
#if os(macOS)
import AppKit
#endif

/**
 빌드시작용
 */
@main
struct MobileAdminApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            EnvironmentModel.self,
        ])

        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do{
            return try ModelContainer(for:schema,
                                      configurations: configuration)
        }catch{
            fatalError("Failed to create ModelContainer:\(error)")
        }
    }()
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #endif

    var body: some Scene {

#if os(iOS)
            MySceneForIOS()
                .modelContainer(sharedModelContainer)
#elseif os(macOS)
            MySceneForMacOS()
                .modelContainer(sharedModelContainer)
#endif


    }
    
     
}
#if os(iOS)
extension UIApplication {
    func endEditing() {
        //sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    let logger = Logger(label:"com.migmig.MobileAdmin.AppDelegate")
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 푸시 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.logger.info("알림 권한 허용됨")
            } else {
                self.logger.warning("알림 권한 거부됨")
            }
        }
        UNUserNotificationCenter.current().delegate = self
        
        // APNs 등록
        UIApplication.shared.registerForRemoteNotifications()
        
        // 앱 실행 중 화면 꺼짐 방지 (Prevent screen from turning off)
        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }

    // 디바이스 토큰 등록 성공 시 호출
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        logger.info("디바이스 토큰 등록 완료")
        // 서버로 토큰 전송 필요
    } 
    // 디바이스 토큰 등록 실패 시 호출
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("APNs 등록 실패: \(error.localizedDescription)")
    }
}
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 포그라운드에서 알림 수신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logger.debug("푸시 알림 수신")
        completionHandler([.banner, .sound])
    }
    
    // 알림 클릭 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logger.debug("알림 클릭")
        completionHandler()
    }
}
#endif

#if os(macOS)
class MacAppDelegate: NSObject, NSApplicationDelegate {
    var activity: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // macOS에서 앱 실행 중 화면 잠금(절전) 방지
        activity = ProcessInfo.processInfo.beginActivity(
            options: .idleDisplaySleepDisabled,
            reason: "App requires screen to stay on"
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let activity = activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
    }
}
#endif