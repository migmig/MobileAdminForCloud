//For iOS
import SwiftUI
struct ErrorListViewForIOS: View {
    @ObservedObject var viewModel:ViewModel
    @State private var searchText = ""
    @State private var isLoading: Bool = false
    @State private var dateFrom:Date = Date()
    @State private var dateTo:Date = Date()


    var filteredErrorItems: [ErrorCloudItem] {
        if searchText.isEmpty {
            return viewModel.errorItems
        }else{
            return viewModel.errorItems.filter{$0.description?.localizedCaseInsensitiveContains(searchText) == true}
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
                        if !isLoading && filteredErrorItems.isEmpty {
                            EmptyStateView(
                                systemImage: "checkmark.shield",
                                title: "오류가 없습니다",
                                description: "조회 기간을 변경해 보세요"
                            )
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

}

#Preview{
    ErrorListViewForIOS(viewModel: .init() )
}
