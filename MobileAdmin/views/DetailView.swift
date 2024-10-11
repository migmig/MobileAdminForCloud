//
//  DetailView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI

struct DetailView: View {
    @Binding var selectedSlidebarItem:SlidebarItem?
    @Binding var selectedEntry : ErrorCloudItem?
    @Binding var toast: Toast?
    var body: some View {
        if(selectedSlidebarItem == SlidebarItem.errerlist){
            if let entry = selectedEntry{
                ErrorCloudItemView(errorCloudItem: entry)
            }else{
                Text("Select a row to view details.")
            }
        }else{
            ToastView(toastItem: $toast)
        }
    }
}
 
