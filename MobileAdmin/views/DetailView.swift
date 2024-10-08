//
//  DetailView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

struct DetailView: View {
    @Binding var selectedEntry : ErrorCloudItem?
    
    var body: some View {
        if let entry = selectedEntry{
            ErrorCloudItemView(errorCloudItem: entry)
        }else{
            Text("Select a row to view details.")
        }
    }
}
 
