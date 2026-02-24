//
//  CodeListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//

import SwiftUI

// MARK: - 개시마감 상태 헬퍼 (iOS/macOS 공용)
struct CloseDeptStatus {
    let label: String
    let code: String
    let icon: String

    static let filters: [CloseDeptStatus] = [
        CloseDeptStatus(label: "전체",     code: "4", icon: "line.3.horizontal.decrease.circle"),
        CloseDeptStatus(label: "미개시",   code: "",  icon: "circle.dashed"),
        CloseDeptStatus(label: "개시",     code: "0", icon: "play.circle.fill"),
        CloseDeptStatus(label: "가마감",   code: "1", icon: "clock.fill"),
        CloseDeptStatus(label: "마감",     code: "2", icon: "checkmark.circle.fill"),
    ]

    static let filtersWithAfterClose: [CloseDeptStatus] = filters + [
        CloseDeptStatus(label: "마감후거래", code: "3", icon: "lock.open.fill"),
    ]

    static func icon(for closegb: String?) -> String {
        switch closegb {
        case "0": return "play.circle.fill"
        case "1": return "clock.fill"
        case "2": return "checkmark.circle.fill"
        case "3": return "lock.open.fill"
        default:  return "circle.dashed"
        }
    }

    static func label(for closegb: String?) -> String {
        switch closegb {
        case "0": return "개시"
        case "1": return "가마감"
        case "2": return "마감"
        case "3": return "마감후거래"
        default:  return "미개시"
        }
    }
}

struct CloseDeptListViewIOS: View {
    @EnvironmentObject var viewModel:ViewModel
    @State var list:[Detail1] = []
    @State var closeGb = "4"

    var filteredList: [Detail1] {
        closeGb == "4" ? list : list.filter{$0.closegb == closeGb}
    }

    private func loadData() async {
       let closeInfo = await viewModel.fetchCloseDeptList()
       list = closeInfo.detail1
   }

    private func count(for code: String) -> Int {
        code == "4" ? list.count : list.filter { $0.closegb == code }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 상태 요약
                if !list.isEmpty {
                    CloseDeptSummaryBar(list: list)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.sm)
                }

                // MARK: - 필터 버튼 바
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(CloseDeptStatus.filters, id: \.code) { filter in
                            FilterChip(
                                label: filter.label,
                                icon: filter.icon,
                                count: count(for: filter.code),
                                isSelected: closeGb == filter.code,
                                color: AppColor.closeDeptStatus(filter.code == "4" ? nil : filter.code),
                                action: {
                                    Task {
                                        withAnimation {
                                            closeGb = filter.code
                                        }
                                        await loadData()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                }

                // MARK: - 결과 카운트
                HStack {
                    Text("\(filteredList.count)건")
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xs)

                List(filteredList){entry in
                    NavigationLink(destination: {
                        CloseDeptDetail(closeDetail: entry)
                    }){
                        CloseDeptListItem(entry: entry)
                    }
                }
                .overlay {
                    if filteredList.isEmpty {
                        EmptyStateView(
                            systemImage: "building.2",
                            title: "데이터가 없습니다",
                            description: "조회 결과가 없습니다"
                        )
                    }
                }
                .refreshable {
                    await loadData()
                }
            }
            .onAppear(){
                Task{
                    await loadData()
                }
            }
            .navigationTitle("지점별 개시 마감 조회")
        }
    }
}

// MARK: - 상태 요약 바
struct CloseDeptSummaryBar: View {
    var list: [Detail1]

    private var closedCount: Int {
        list.filter { $0.closegb == "2" || $0.closegb == "3" }.count
    }

    private var progress: Double {
        list.isEmpty ? 0 : Double(closedCount) / Double(list.count)
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // 상태별 건수
            HStack(spacing: 0) {
                ForEach(CloseDeptStatus.filters.dropFirst(), id: \.code) { status in
                    let cnt = list.filter { $0.closegb == status.code }.count
                    VStack(spacing: AppSpacing.xxs) {
                        Image(systemName: status.icon)
                            .font(.caption2)
                            .foregroundColor(AppColor.closeDeptStatus(status.code))
                        Text("\(cnt)")
                            .font(.system(.caption, design: .rounded).bold())
                        Text(status.label)
                            .font(.system(.caption2))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // 마감 진행률 바
            VStack(spacing: AppSpacing.xxs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.12))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColor.closeDeptStatus("2"))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("마감 진행률")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundColor(AppColor.closeDeptStatus("2"))
                }
            }
        }
        .padding(AppSpacing.md)
        .cardBackground()
        .cornerRadius(AppRadius.lg)
    }
}

// MARK: - 필터 칩 (아이콘 + 건수 지원)
struct FilterChip: View {
    var label: String
    var icon: String? = nil
    var count: Int? = nil
    var isSelected: Bool
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(.caption2, weight: isSelected ? .semibold : .regular))
                }
                Text(label)
                    .font(AppFont.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(.caption2, design: .rounded).bold())
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 1)
                        .background(isSelected ? color.opacity(0.25) : Color.secondary.opacity(0.12))
                        .cornerRadius(AppRadius.xs)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? color.opacity(0.15) : Color.clear)
            .foregroundColor(isSelected ? color : .secondary)
            .contentShape(Rectangle())
            .cornerRadius(AppRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .strokeBorder(isSelected ? color : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) \(count ?? 0)건")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 개시마감 리스트 아이템
struct CloseDeptListItem: View {
    var entry: Detail1

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: CloseDeptStatus.icon(for: entry.closegb))
                .foregroundColor(AppColor.closeDeptStatus(entry.closegb))
                .font(.body)
                .frame(width: AppIconSize.md)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(entry.deptprtnm ?? "")
                    .font(AppFont.listTitle)
                if let rmk = entry.rmk, !rmk.isEmpty {
                    Text(rmk)
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(CloseDeptStatus.label(for: entry.closegb))
                .font(AppFont.captionSmall)
                .fontWeight(.medium)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(AppColor.closeDeptStatus(entry.closegb).opacity(0.12))
                .foregroundColor(AppColor.closeDeptStatus(entry.closegb))
                .cornerRadius(AppRadius.sm)
        }
        .padding(.vertical, AppSpacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.deptprtnm ?? ""), \(CloseDeptStatus.label(for: entry.closegb))")
    }
}

#Preview{
    CloseDeptListViewIOS()
        .environmentObject(ViewModel())
}
