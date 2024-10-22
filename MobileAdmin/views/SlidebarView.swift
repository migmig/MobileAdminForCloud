//
//  SlidebarView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/11/24.
//

import SwiftUI

enum SlidebarItem: Hashable {
    case errerlist,toast
    case collection(String)
    
    var title: String{
        switch self{
        case .errerlist: 
            return "Error List"
        case .toast:
            return "Toast"
        case .collection(let title):
            return title
        }
    }
}


struct SlidebarView: View {
    @Binding var selection: SlidebarItem? 
    var body: some View {
        List(selection:$selection){
            Section(header:Text("Slidebar")){
                NavigationLink(value:SlidebarItem.errerlist){
                    Text(SlidebarItem.errerlist.title)
                }
                NavigationLink(value:SlidebarItem.toast){
                    Text(SlidebarItem.toast.title)
                }
            }
            
        }
    }
}

