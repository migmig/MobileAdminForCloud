//
//  ContentViewForMac.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/11/24.
//

import SwiftUI

struct ContentViewForMac: View {
    @ObservedObject var viewModel:ViewModel
    @State var errorItems:[ErrorCloudItem] = []
    @State var selectedEntry:ErrorCloudItem? = nil
    @State var toast:Toast?
    
    @State private var selectedSidebarItem: SlidebarItem? = SlidebarItem.toast
    var body: some View {
        NavigationSplitView{
            SlidebarView(selection: $selectedSidebarItem)
        }content:{
            ContentListView(
                viewModel : viewModel,
                            selectedSlidebarItem: $selectedSidebarItem,
                            toast: $toast,
                            errorItems: $errorItems,
                            selectedEntry: $selectedEntry
            )
        }detail:{
            DetailView(
                viewModel : viewModel,
                       selectedSlidebarItem: $selectedSidebarItem,
                       selectedEntry: $selectedEntry,
                       toast:$toast
            )
        }
        
    }
}
 
