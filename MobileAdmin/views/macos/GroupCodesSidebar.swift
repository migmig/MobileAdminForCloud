//
//  GroupCodesSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//
import SwiftUI

struct GroupCodesSidebar: View {
    @EnvironmentObject var codeViewModel: CodeViewModel
    @Binding var selectedGroupCode: CmmnGroupCodeItem?
    @State private var groupCodes: [CmmnGroupCodeItem]? = nil
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var useAtFilter: String = "all"

    var filteredGroupCodes: [CmmnGroupCodeItem] {
        (groupCodes ?? [])
            .sorted { $0.cmmnGroupCode < $1.cmmnGroupCode }
            .filter {
                (searchText.isEmpty ||
                 $0.cmmnGroupCodeNm?.localizedCaseInsensitiveContains(searchText) == true ||
                 $0.cmmnGroupCode.localizedCaseInsensitiveContains(searchText))
                && (useAtFilter == "all" || $0.useAt == useAtFilter)
            }
    }

    private func count(for code: String) -> Int {
        let all = groupCodes ?? []
        return code == "all" ? all.count : all.filter { $0.useAt == code }.count
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
                            action: {
                                withAnimation { useAtFilter = filter.code }
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
            }

            // MARK: - 리스트
            if isLoading {
                ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
            }
            List(selection: $selectedGroupCode) {
                ForEach(filteredGroupCodes, id: \.self) { entry in
                    NavigationLink(value: entry) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: UseAtStatus.icon(for: entry.useAt))
                                .foregroundColor(UseAtStatus.color(for: entry.useAt))

                            Text(entry.cmmnGroupCode)
                                .font(AppFont.mono)
                                .foregroundColor(.secondary)

                            Text(entry.cmmnGroupCodeNm ?? "")

                            Spacer()

                            Text(UseAtStatus.label(for: entry.useAt))
                                .font(AppFont.captionSmall)
                                .fontWeight(.medium)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xxs)
                                .background(UseAtStatus.color(for: entry.useAt).opacity(0.12))
                                .foregroundColor(UseAtStatus.color(for: entry.useAt))
                                .cornerRadius(AppRadius.sm)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .automatic)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task {
                        isLoading = true
                        groupCodes = await codeViewModel.fetchGroupCodeLists()
                        isLoading = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .navigationTitle("코드 조회")
        #if os(macOS)
        .navigationSubtitle("\(filteredGroupCodes.count)건의 코드")
        #endif
        .loadingTask(isLoading: $isLoading) {
            groupCodes = await codeViewModel.fetchGroupCodeLists()
        }
    }
}

#Preview {
    GroupCodesSidebar(
        selectedGroupCode: .constant(nil)
    )
    .environmentObject(CodeViewModel())
}
