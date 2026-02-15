//For iOS
import SwiftUI
struct ErrorListViewForIOS: View {
    @ObservedObject var viewModel:ViewModel
    @State private var searchText = ""
    @State private var searchField: SearchField = .description
    @State private var isLoading: Bool = false
    @State private var dateFrom:Date = Date()
    @State private var dateTo:Date = Date()
    @State private var emptyStateContext: EmptyStateContext = .noData
    @State private var autoRefresh: Bool = false
    @State private var timerProgress: Double = 0
    @State private var timer: Timer? = nil
    @State private var isFetching: Bool = false
    @ObservedObject var toastManager = ToastManager()
    let timeInterval: Double = 0.01


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
            VStack(spacing: 0) {
                List{
                    Section {
                        SearchArea(dateFrom: $dateFrom,
                                   dateTo: $dateTo,
                                   isLoading: $isLoading,
                                   clearAction:{
                            searchText = ""
                        }){
                            viewModel.errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo:  dateTo) ?? []
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    // 정렬/필터 바 (Phase 2)
                    Section {
                        SortAndFilterBar(
                            sortConfiguration: $viewModel.sortConfiguration,
                            filterCount: severityFilterCount
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    // 검색 필드 선택
                    Section {
                        Picker("검색 필드", selection: $searchField) {
                            ForEach(SearchField.allCases, id: \.self) { field in
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "magnifyingglass")
                                        .font(AppFont.caption)
                                    Text(field.displayName)
                                }
                                .tag(field)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    // 심각도 필터 (Phase 2)
                    Section {
                        SeverityFilterView(
                            selectedSeverity: $viewModel.severityFilter,
                            severityItemCounts: calculateSeverityCount()
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    // 자동새로고침 토글
                    Section {
                        AutoRefreshToggleView(
                            isAutoRefresh: $autoRefresh,
                            timerProgress: $timerProgress,
                            isFetching: $isFetching,
                            toastManager: toastManager
                        )
                        .onChange(of: autoRefresh) { _, newValue in
                            if newValue {
                                startAutoRefresh()
                            } else {
                                stopAutoRefresh()
                            }
                        }
                        .onChange(of: isFetching) { _, newValue in
                            if newValue && autoRefresh {
                                Task {
                                    viewModel.errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
                                    isFetching = false
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    // 결과 요약
                    Section {
                        HStack(spacing: AppSpacing.sm) {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColor.error)
                                .font(AppFont.caption)
                            Text("\(filteredErrorItems.count)건의 오류")
                                .font(AppFont.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }

                    // 오류 목록
                    Section {
                        if filteredErrorItems.isEmpty {
                            EmptyStateView(context: emptyState)
                                .listRowBackground(Color.clear)
                        }
                        ForEach(filteredErrorItems, id:\.id){ entry in
                            NavigationLink(destination: ErrorCloudItemView(viewModel:viewModel,
                                                                           errorCloudItem: entry)){
                                ErrorCloudListItem(errorCloudItem: entry)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, placement: .automatic)
                .navigationTitle("오류 조회")
            }
        .loadingTask(isLoading: $isLoading) {
            viewModel.errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
        }
        .refreshable {
            isLoading = true
            viewModel.errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
            isLoading = false
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

#Preview{
    ErrorListViewForIOS(viewModel: .init() )
}
