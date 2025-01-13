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
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
