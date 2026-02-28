import SwiftUI

struct CodeListViewIOS: View {
    @EnvironmentObject var codeViewModel: CodeViewModel
    @State private var cmmnGroupCodeItems: [CmmnGroupCodeItem] = []
    @State private var isLoading = false
    @State private var searchText: String = ""
    @State private var useAtFilter: String = "all"

    var filteredList: [CmmnGroupCodeItem] {
        cmmnGroupCodeItems
            .sorted { $0.cmmnGroupCode < $1.cmmnGroupCode }
            .filter {
                (searchText.isEmpty ||
                 $0.cmmnGroupCodeNm?.localizedCaseInsensitiveContains(searchText) == true ||
                 $0.cmmnGroupCode.localizedCaseInsensitiveContains(searchText))
                && (useAtFilter == "all" || $0.useAt == useAtFilter)
            }
    }

    private func loadData() async {
        isLoading = true
        cmmnGroupCodeItems = await codeViewModel.fetchGroupCodeLists()
        isLoading = false
    }

    private func count(for code: String) -> Int {
        code == "all" ? cmmnGroupCodeItems.count
                      : cmmnGroupCodeItems.filter { $0.useAt == code }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 필터 바
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(UseAtStatus.filters, id: \.code) { filter in
                        FilterChip(
                            label: filter.label,
                            icon: filter.icon,
                            count: count(for: filter.code),
                            isSelected: useAtFilter == filter.code,
                            color: UseAtStatus.color(for: filter.code == "all" ? "Y" : filter.code),
                            action: { withAnimation { useAtFilter = filter.code } }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
            }

            HStack {
                Text("\(filteredList.count)건")
                    .font(AppFont.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xs)

            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView().controlSize(.small)
                        Text("로딩 중...")
                            .font(AppFont.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                ForEach(filteredList, id: \.self) { item in
                    NavigationLink(destination: CodeDetailView(cmmnGroupCodeItem: item)) {
                        GroupCodeListItem(item: item)
                    }
                }
            }
            .overlay {
                if !isLoading && filteredList.isEmpty {
                    EmptyStateView(
                        systemImage: "doc.text.magnifyingglass",
                        title: "코드가 없습니다",
                        description: searchText.isEmpty ? nil : "검색 조건을 변경해 보세요"
                    )
                }
            }
            .searchable(text: $searchText, placement: .automatic)
            .refreshable { await loadData() }
        }
        .navigationTitle("코드 조회")
        .loadingTask(isLoading: $isLoading) {
            cmmnGroupCodeItems = await codeViewModel.fetchGroupCodeLists()
        }
    }
}

// MARK: - 그룹코드 리스트 아이템
struct GroupCodeListItem: View {
    var item: CmmnGroupCodeItem

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(item.cmmnGroupCode)
                .font(AppFont.mono)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.link.gradient)
                .cornerRadius(AppRadius.xs)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(item.cmmnGroupCodeNm ?? "")
                    .font(AppFont.listTitle)
                Text("그룹코드")
                    .font(AppFont.captionSmall)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(UseAtStatus.label(for: item.useAt))
                .font(AppFont.captionSmall)
                .fontWeight(.medium)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(UseAtStatus.color(for: item.useAt).opacity(0.12))
                .foregroundColor(UseAtStatus.color(for: item.useAt))
                .cornerRadius(AppRadius.sm)
        }
        .padding(.vertical, AppSpacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.cmmnGroupCode), \(item.cmmnGroupCodeNm ?? ""), \(UseAtStatus.label(for: item.useAt))")
    }
}

#Preview {
    NavigationStack {
        CodeListViewIOS()
            .environmentObject(CodeViewModel())
    }
}
