//
//  HomeViewForIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/15/25.
//

import SwiftUI

struct HomeViewForIOS: View {
    @StateObject var viewModel:ViewModel = ViewModel()
    var body: some View {
        NavigationStack{
            List{
                NavigationLink(destination: ErrorListViewForIOS(viewModel: viewModel)){
                    Label(SlidebarItem.errerlist.title , systemImage: SlidebarItem.errerlist.img)
                }
                NavigationLink(destination: GoodsListViewIOS(viewModel: viewModel)){
                    Label(SlidebarItem.goodsInfo.title , systemImage: SlidebarItem.goodsInfo.img)
                }
                NavigationLink(destination: CodeListViewIOS(viewModel: viewModel)){ 
                    Label(SlidebarItem.codeList.title  , systemImage: SlidebarItem.codeList.img)
                }
                NavigationLink(destination: EdcClsSidebarIOS(viewModel: viewModel)){
                    Label(SlidebarItem.gcpClsList.title , systemImage: SlidebarItem.gcpClsList.img)
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeViewForIOS(viewModel: ViewModel())
}
