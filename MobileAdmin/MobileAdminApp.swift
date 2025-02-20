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
            let container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
            return try ModelContainer(for:schema,
                                      configurations: configuration)
        }catch{
            fatalError("Failed to create ModelContainer:\(error)")
        }
    }()
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 푸시 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨")
            }
        }
        UNUserNotificationCenter.current().delegate = self
        
        // APNs 등록
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }

    // 디바이스 토큰 등록 성공 시 호출
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("디바이스 토큰: \(token)")
        // 서버로 토큰 전송 필요
    } 
    // 디바이스 토큰 등록 실패 시 호출
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs 등록 실패: \(error.localizedDescription)")
    }
}
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 포그라운드에서 알림 수신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("푸시 알림 수신: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound])
    }
    
    // 알림 클릭 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("알림 클릭: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
}
#endif
