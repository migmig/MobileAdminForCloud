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
    @State private var searchText = ""
    var filteredErrorItems: [ErrorCloudItem] {
        if searchText.isEmpty {
            return errorItems
        }else{
            return errorItems.filter{$0.description?.localizedCaseInsensitiveContains(searchText) == true}
        }
    }
    
    var body: some View {
        if isLoading {
           ProgressView("데이터를 불러오는 중...")
               .progressViewStyle(CircularProgressViewStyle())
        }
        
        if(selectedSlidebarItem == SlidebarItem.errerlist){
            VStack{
                // 검색창 추가
               HStack {
                   Image(systemName: "magnifyingglass")
                       .foregroundColor(.gray) // 아이콘 색상
                       .padding(.leading, 10) // 아이콘 왼쪽 패딩
                   
                   TextField("검색어 입력...", text: $searchText)
                       .padding(10)
//                       .background(Color(UIColor.systemGray6)) // 배경 색상
                       .cornerRadius(10) // 모서리 둥글게
                       .font(.system(size: 16)) // 폰트 크기
               }
               .padding(.horizontal) // 전체 HStack의 패딩
                
                List(filteredErrorItems,selection:$selectedEntry){entry in
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
