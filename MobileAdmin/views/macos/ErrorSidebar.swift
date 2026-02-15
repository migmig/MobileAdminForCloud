//
//  ErrorSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/4/24.
//

import SwiftUI

struct ErrorSidebar: View {
    @ObservedObject var viewModel:ViewModel
    @Binding var selectedErrorItem:ErrorCloudItem?
    @State private var searchText = ""
    @State private var searchField: SearchField = .description
    @State var isLoading:Bool = false
    @State var dateFrom:Date = Date()
    @State var dateTo:Date = Date()
    @State var autoRefresh:Bool = false
    @State var timerProgress: Double = 0 // 슬라이더 값
    @State var timer: Timer? = nil // 타이머 객체
    @State private var isFetching: Bool = false // 자동 조회 중복 방지
    @ObservedObject var toastManager = ToastManager()
    var timeInterval:Double = 0.01 // 타이머 간격

   var severityFilterCount: Int {
       var count = 0
       if viewModel.severityFilter != nil { count += 1 }
       return count
   }

   var filteredErrorItems: [ErrorCloudItem] {
       // 1. 먼저 집계 (중복 카운팅)
       var items = viewModel.aggregateErrorOccurrences(viewModel.errorItems)

       // 2. 텍스트 검색 적용
       if !searchText.isEmpty {
           items = items.filter { searchField.matches(item: $0, query: searchText) }
       }

       // 3. 심각도 필터 적용
       items = viewModel.applySeverityFilter(items)

       // 4. 정렬 적용
       items = viewModel.applySorting(items)

       return items
   }

    var emptyState: EmptyStateContext {
        if isLoading {
            return .loading
        } else if !searchText.isEmpty && filteredErrorItems.isEmpty {
            return .noResults
        } else if viewModel.errorItems.isEmpty {
            return .noData
        } else {
            return .filterEmpty
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
            .searchable(text: $searchText , placement: .automatic)

            // 정렬/필터 바 (Phase 2)
            SortAndFilterBar(
                sortConfiguration: $viewModel.sortConfiguration,
                filterCount: severityFilterCount
            )

            // 검색 필드 선택
            Picker("검색 필드", selection: $searchField) {
                ForEach(SearchField.allCases, id: \.self) { field in
                    Text(field.displayName).tag(field)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, AppSpacing.sm)

            // 심각도 필터 (Phase 2)
            SeverityFilterView(
                selectedSeverity: $viewModel.severityFilter,
                severityItemCounts: calculateSeverityCount()
            )

            HStack{
                if autoRefresh{
                    HStack {
                        GeometryReader { geometry in
                            ZStack {
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
                            .font(AppFont.monoDigit)
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
                    NavigationLink(value:entry){
                        ErrorCloudListItem(errorCloudItem: entry)
                    }
                }
                .overlay {
                    if filteredErrorItems.isEmpty {
                        EmptyStateView(context: emptyState)
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
                .loadingTask(isLoading: $isLoading) {
                    let errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
                    viewModel.errorItems = errorItems
                }
                .onChange(of:viewModel.errorItems){_,_ in
                    proxy.scrollTo(viewModel.errorItems.first, anchor: .top)
                }
            }
        }
    }
    
    private func startAutoRefresh() {
        timerProgress = 0
        isFetching = false
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            timerProgress += timeInterval
            if timerProgress >= 5 && !isFetching {
                isFetching = true
                timerProgress = 0
                Task { @MainActor in
                    let errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
                    viewModel.errorItems = errorItems
                    isFetching = false
                }
            }
        }
    }
    
    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
        timerProgress = 0
        isFetching = false
    }

    /// 심각도별 오류 개수 계산
    private func calculateSeverityCount() -> [SeverityLevel: Int] {
        var counts: [SeverityLevel: Int] = [
            .critical: 0,
            .high: 0,
            .medium: 0,
            .low: 0
        ]

        for item in viewModel.errorItems {
            let severity = item.severity ?? SeverityLevel.derived(from: item)
            counts[severity, default: 0] += 1
        }

        return counts
    }
}
 #Preview {
    ErrorSidebar(
        viewModel: ViewModel(),
        selectedErrorItem: .constant(nil
        )
    )
}
