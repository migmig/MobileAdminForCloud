//
//  ErrorSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/4/24.
//

import SwiftUI

struct ErrorSidebar: View {
//    @Binding var errorItems:[ErrorCloudItem]
    @ObservedObject var viewModel:ViewModel
    @Binding var selectedErrorItem:ErrorCloudItem?
    @State private var searchText = ""
    @State var isLoading:Bool = false
    @State var dateFrom:Date = Date()
    @State var dateTo:Date = Date()
    @State var autoRefresh:Bool = false
    @State var timerProgress: Double = 0 // 슬라이더 값
    @State var timer: Timer? = nil // 타이머 객체
    @ObservedObject var toastManager = ToastManager()
    var timeInterval:Double = 0.01 // 타이머 간격
   
   var filteredErrorItems: [ErrorCloudItem] {
       if searchText.isEmpty {
           return viewModel.errorItems
       }else{
           return viewModel.errorItems.filter{$0.description?.localizedCaseInsensitiveContains(searchText) == true}
       }
   }
    
    var body: some View {
        VStack{
            
            SearchArea(dateFrom: $dateFrom,
                       dateTo: $dateTo,
                       isLoading: $isLoading,
                       clearAction: {searchText = ""}){
                Task{
                        let errorItems = await viewModel.fetchErrors(startFrom: dateFrom,
                                                                     endTo:  dateTo) ?? []
                        viewModel.errorItems = errorItems
                }
            }
            .padding()
//            .padding(.horizontal) // 전체 HStack의 패딩
            .searchable(text: $searchText , placement: .automatic)
            HStack{
                if autoRefresh{
                    HStack {
                        GeometryReader { geometry in
                            ZStack {
//                                // 슬라이더 배경
//                                RoundedRectangle(cornerRadius: 10)
//                                    .fill(Color.gray.opacity(0.2))
//                                    .frame(height: 12)
                                
                                // 진행도 바
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.blue, .green]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(
                                        width: CGFloat(timerProgress / 5) * geometry.size.width * 0.8,
                                        height: 12
                                    )
                            }
                            .frame(height: 12)
                            .padding(.horizontal)
                        }
                        .frame(height: 12) // 고정된 높이 설정
                        
                        // 슬라이더 설명 텍스트
                        Text("자동 새로고침 진행: \(Int((timerProgress / 5) * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                }else{
                    Spacer()
                }
                Toggle("5초마다 자동 조회", isOn: $autoRefresh)
                .onChange(of: autoRefresh) { _, newValue in
                    if newValue {
                        toastManager.showToast(message: "자동 새로고침이 시작되었습니다.")
                        startAutoRefresh()
                    } else {
                        toastManager.showToast(message: "자동 새로고침이 종료되었습니다.")
                        stopAutoRefresh()
                    }
                }
                .padding(.horizontal)
            }
            ScrollViewReader { proxy in
                List(filteredErrorItems,selection:$selectedErrorItem){entry in
//                    NavigationLink(value:entry){
//                        ErrorCloudListItem(errorCloudItem: entry)
//                    }
                    NavigationLink(destination: ErrorCloudItemView(errorCloudItem: entry)){
                        ErrorCloudListItem(errorCloudItem: entry)
                    }
                }
                .navigationTitle("오류 조회")
                #if os(macOS)
                .navigationSubtitle("  \(filteredErrorItems.count)개의 오류")
                #endif
                .navigationSplitViewColumnWidth(min:200,ideal: 200)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .onAppear()
                {
                    Task{
                        isLoading = true;
                        print("start")
                        let errorItems = await viewModel.fetchErrors(startFrom: dateFrom,
                                                                 endTo:  dateTo) ?? []
                        viewModel.errorItems = errorItems
                        print("end")
                        isLoading = false;
                    }
                }
                .onChange(of:viewModel.errorItems){_,_ in
                    proxy.scrollTo(viewModel.errorItems.first, anchor: .top)
                }
            }
        }
    }
    
    private func startAutoRefresh() {
        timerProgress = 0
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
            timerProgress += timeInterval
            if timerProgress >= 5 {
                Task {
                    DispatchQueue.main.async {
                        timerProgress = 0
                    }
                    let errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
                    DispatchQueue.main.async {
                        viewModel.errorItems = errorItems
                    }
                }
            }
        }
    }
    
    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
        timerProgress = 0
    }
}
 #Preview {
    ErrorSidebar(
        viewModel: ViewModel(),
        selectedErrorItem: .constant(nil
        )
    )
}
