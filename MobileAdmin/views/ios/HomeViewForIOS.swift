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
                    Label("오류 조회" , systemImage: "cloud")
                }
                NavigationLink(destination: GoodsListViewIOS(viewModel: viewModel)){
                    Label("상품 조회" , systemImage: "cart")
                }
                NavigationLink(destination: CodeListViewIOS(viewModel: viewModel)){
                    Label("코드 조회" , systemImage: "list.bullet")
                }
                NavigationLink(destination: EdcClsSidebarIOS(viewModel: viewModel)){
                    Label("교육 조회" , systemImage: "book")
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeViewForIOS(viewModel: ViewModel())
}
