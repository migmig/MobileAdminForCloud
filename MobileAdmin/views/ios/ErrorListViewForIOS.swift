//For iOS
import SwiftUI

struct ErrorListViewForIOS: View {
    @ObservedObject var viewModel: ViewModel
    @State private var searchText = ""
    @State private var isLoading: Bool = false
    @State private var dateFrom: Date = Date()
    @State private var dateTo: Date = Date()
    @State private var userIdForLog: String = ""
    @State private var isDownloadingLog: Bool = false
    @State private var downloadedFileURL: URL? = nil

    private var criticalCount: Int {
        viewModel.errorItems.filter { isCriticalError(code: $0.code) }.count
    }

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
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                modernSummaryHeader
                filterPanel
                userLogPanel
                resultHeader

                if isLoading {
                    loadingPanel
                } else if filteredErrorItems.isEmpty {
                    EmptyStateView(
                        systemImage: "checkmark.shield",
                        title: "오류가 없습니다",
                        description: searchText.isEmpty ? "조회 기간을 변경해 보세요" : "검색어를 변경해 보세요"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                } else {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(filteredErrorItems, id: \.id) { entry in
                            NavigationLink(destination: ErrorCloudItemView(viewModel: viewModel,
                                                                           errorCloudItem: entry)) {
                                ErrorCloudListItem(errorCloudItem: entry)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.xs)
                                    .cardBackground()
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .groupedBackground()
        .searchable(text: $searchText, placement: .automatic, prompt: "설명, 코드, 사용자, URL 검색")
        .navigationTitle("오류 조회")
        .loadingTask(isLoading: $isLoading) {
            viewModel.errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
        }
        .refreshable {
            await fetchErrors()
        }
    }

    private var modernSummaryHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("오류 모니터링")
                .font(.title3.weight(.bold))

            HStack(spacing: AppSpacing.sm) {
                SummaryCard(title: "조회 결과", value: "\(filteredErrorItems.count)", icon: "list.bullet.rectangle", tint: .blue)
                SummaryCard(title: "전체 오류", value: "\(viewModel.errorItems.count)", icon: "exclamationmark.bubble.fill", tint: AppColor.error)
                SummaryCard(title: "고위험(5xx)", value: "\(criticalCount)", icon: "bolt.fill", tint: .orange)
            }
        }
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SearchArea(dateFrom: $dateFrom,
                       dateTo: $dateTo,
                       isLoading: $isLoading,
                       clearAction: {
                searchText = ""
            }) {
                viewModel.errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo) ?? []
            }

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
            }
        }
        .padding(AppSpacing.md)
        .cardBackground()
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .cardShadow()
    }

    private var userLogPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("사용자 로그 다운로드")
                .font(.headline)

            HStack {
                TextField("사용자 아이디 입력", text: $userIdForLog)
                    .textFieldStyle(.roundedBorder)
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
                        Label("다운로드", systemImage: "square.and.arrow.down.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(userIdForLog.isEmpty || isDownloadingLog)
            }
        }
        .padding(AppSpacing.md)
        .cardBackground()
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .cardShadow()
    }

    private var resultHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "tray.full.fill")
                .foregroundStyle(.secondary)
            Text("오류 목록")
                .font(.headline)
            Spacer()
            Text("\(filteredErrorItems.count)건")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            if !searchText.isEmpty {
                Text("/ 전체 \(viewModel.errorItems.count)건")
                    .font(AppFont.captionSmall)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var loadingPanel: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView()
                .controlSize(.small)
            Text("오류 데이터를 불러오는 중입니다...")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .cardBackground()
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    private func isCriticalError(code: String?) -> Bool {
        guard let code, !code.isEmpty else { return false }
        let upper = code.uppercased()
        if upper.hasPrefix("5") || upper.contains("_5") {
            return true
        }
        return false
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
                downloadedFileURL = nil
            }
            isDownloadingLog = false
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)

            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(tint.opacity(0.08))
        )
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
                        .fill(Color.accentColor.opacity(0.14))
                )
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ErrorListViewForIOS(viewModel: .init())
}
