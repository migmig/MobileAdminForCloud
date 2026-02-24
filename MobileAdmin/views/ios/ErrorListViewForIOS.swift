//For iOS
import SwiftUI
struct ErrorListViewForIOS: View {
    @ObservedObject var viewModel:ViewModel
    @State private var searchText = ""
    @State private var isLoading: Bool = false
    @State private var dateFrom:Date = Date()
    @State private var dateTo:Date = Date()
    @State private var userIdForLog: String = ""
    @State private var isDownloadingLog: Bool = false
    @State private var downloadedFileURL: URL? = nil

    var filteredErrorItems: [ErrorCloudItem] {
        if searchText.isEmpty {
            return viewModel.errorItems
        } else {
            let query = searchText.lowercased()
            return viewModel.errorItems.filter { item in
                item.description?.localizedCaseInsensitiveContains(query) == true
                || item.msg?.localizedCaseInsensitiveContains(query) == true
                || item.code?.localizedCaseInsensitiveContains(query) == true
                || item.userId?.localizedCaseInsensitiveContains(query) == true
                || item.restUrl?.localizedCaseInsensitiveContains(query) == true
            }
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

                        // 빠른 날짜 프리셋
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.sm) {
                                DatePresetButton(label: "오늘") {
                                    dateFrom = Calendar.current.startOfDay(for: Date())
                                    dateTo = Date()
                                    await fetchErrors()
                                }
                                DatePresetButton(label: "최근 3일") {
                                    dateFrom = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
                                    dateTo = Date()
                                    await fetchErrors()
                                }
                                DatePresetButton(label: "최근 7일") {
                                    dateFrom = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                                    dateTo = Date()
                                    await fetchErrors()
                                }
                                DatePresetButton(label: "최근 30일") {
                                    dateFrom = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                                    dateTo = Date()
                                    await fetchErrors()
                                }
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    // MARK: - 사용자 로그 다운로드
                    Section("사용자 로그 다운로드") {
                        HStack {
                            TextField("사용자 아이디 입력", text: $userIdForLog)
                                .onSubmit { triggerUserLogDownload() }
                            if let fileURL = downloadedFileURL {
                                ShareLink(item: fileURL) {
                                    Label("공유", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            Button(action: triggerUserLogDownload) {
                                if isDownloadingLog {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "square.and.arrow.down.fill")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(userIdForLog.isEmpty || isDownloadingLog)
                        }
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
                            if !searchText.isEmpty {
                                Text("(전체 \(viewModel.errorItems.count)건)")
                                    .font(AppFont.captionSmall)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    // 오류 목록
                    Section {
                        if !isLoading && filteredErrorItems.isEmpty {
                            EmptyStateView(
                                systemImage: "checkmark.shield",
                                title: "오류가 없습니다",
                                description: searchText.isEmpty ? "조회 기간을 변경해 보세요" : "검색어를 변경해 보세요"
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
                .searchable(text: $searchText, placement: .automatic, prompt: "설명, 코드, 사용자, URL 검색")
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

    private func fetchErrors() async {
        isLoading = true
        viewModel.errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
        isLoading = false
    }

    private func triggerUserLogDownload() {
        guard !userIdForLog.isEmpty else { return }
        isDownloadingLog = true
        downloadedFileURL = nil
        Task {
            do {
                let fileURL = try await viewModel.downloadUserLog(userIdForLog)
                downloadedFileURL = fileURL
            } catch {
                // 다운로드 실패 시 파일 URL 초기화
                downloadedFileURL = nil
            }
            isDownloadingLog = false
        }
    }

}

// MARK: - 날짜 프리셋 버튼
struct DatePresetButton: View {
    let label: String
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Text(label)
                .font(AppFont.captionSmall)
                .fontWeight(.medium)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.1))
                )
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
    }
}

#Preview{
    ErrorListViewForIOS(viewModel: .init() )
}
