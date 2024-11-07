//
//  ErrorSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/4/24.
//

import SwiftUI

struct ErrorSidebar: View {
    @Binding var errorItems:[ErrorCloudItem]
    @Binding var selectedErrorItem:ErrorCloudItem?
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @State private var searchText = ""
    @State var isLoading:Bool = false
    @State var dateFrom:Date = Date()
    @State var dateTo:Date = Date()
    
   
   var filteredErrorItems: [ErrorCloudItem] {
       if searchText.isEmpty {
           return errorItems
       }else{
           return errorItems.filter{$0.description?.localizedCaseInsensitiveContains(searchText) == true}
       }
   }
    
    var body: some View {
        VStack{
            SearchArea(dateFrom: $dateFrom,
                       dateTo: $dateTo,
                       isLoading: $isLoading,
                       clearAction: {searchText = ""}){
                    errorItems = await viewModel.fetchErrors(startFrom: dateFrom,
                                                             endTo:  dateTo) ?? []
            }
            .padding()
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
               Text("\(filteredErrorItems.count)개의 오류")
           }
           .padding(.horizontal) // 전체 HStack의 패딩
            
            List(filteredErrorItems,selection:$selectedErrorItem){entry in
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
                    print("start")
                    await errorItems = viewModel.fetchErrors(startFrom: dateFrom
                                                             , endTo:  dateTo) ?? []
                    print("end")
                    isLoading = false;
                }
            }
        }
    }
}
 #Preview {
    ErrorSidebar(
        errorItems: .constant([]),
        selectedErrorItem: .constant(nil)
    )
}
