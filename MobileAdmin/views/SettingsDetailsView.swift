//
//  SettingsDetailsView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/10/24.
//

import SwiftUI

struct SettingsDetailsView: View {
    let title : String
    
    @AppStorage("option1") private var option1 = true
    @AppStorage("option2") private var option2 = false
    
    var body: some View {
        Form{
            Section{
                Toggle("Enable option 1", isOn: $option1)
                    .toggleStyle(.automatic)
                Toggle("Enable option 2", isOn: $option2)
                    .toggleStyle(.automatic)
            }
        }
        .navigationTitle(title)
    }
}
 
