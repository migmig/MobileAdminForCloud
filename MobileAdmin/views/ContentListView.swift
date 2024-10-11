//
//  ContentListView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/11/24.
//

import SwiftUI

struct ContentListView: View {
    @Binding var selectedSlidebarItem:SlidebarItem?
    
    var formatDate:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 날짜 형식을 설정
        return formatter.string(from: Date()) // 포맷된 문자열 반환
    }
     
    @StateObject var viewModel = ViewModel()
    @Binding var toast:Toast?
    @Binding var errorItems:[ErrorCloudItem]
    @Binding var selectedEntry:ErrorCloudItem?
    @State private var isLoading:Bool = false
    
    var body: some View {
        if isLoading {
           ProgressView("데이터를 불러오는 중...")
               .progressViewStyle(CircularProgressViewStyle())
        }
        
        if(selectedSlidebarItem == SlidebarItem.errerlist){
            
            List(errorItems,selection:$selectedEntry){entry in
                NavigationLink(value:entry){
                    ErrorCloudListItem(errorCloudItem: entry)
                }
            }
            .navigationSplitViewColumnWidth(min:200,ideal: 200)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .onAppear()
            {
                Task{
                    isLoading = true;
                    await errorItems = viewModel.fetchErrors(startFrom: formatDate, endTo:  formatDate) ?? []
                    isLoading = false;
                }
            }
        }else{
            List{
                NavigationLink(value:toast){
                    Text(toast?.noticeHder ?? "")
                }
            }.onAppear()
            {
                Task{
                    isLoading = true;
                    await toast = viewModel.fetchToasts()
                    isLoading = false;
                }
            }
        }
    }
}
