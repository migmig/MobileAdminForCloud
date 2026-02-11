//
//  CodeListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//

import SwiftUI

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

    var buttonsArr : [[String:String]] = [
                                           ["전체"   : "4" ]
                                         , ["미개시" : ""  ]
                                         , ["개시"   : "0" ]
                                         , ["가마감" : "1" ]
                                         , ["마감"   : "2" ]
                                        ]

    var body: some View {

        NavigationStack {
            VStack(spacing: 0) {
                // 필터 버튼 바
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(buttonsArr, id:\.self){ button in
                            FilterChip(
                                label: button.keys.first!,
                                isSelected: closeGb == button.values.first!,
                                color: AppColor.closeDeptStatus(button.values.first!),
                                action: {
                                    Task {
                                        withAnimation {
                                            closeGb = button.values.first!
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

                // 결과 카운트
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

// MARK: - 필터 칩 (재사용 가능)
struct FilterChip: View {
    var label: String
    var isSelected: Bool
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? color.opacity(0.15) : Color.clear)
                .foregroundColor(isSelected ? color : .secondary)
                .cornerRadius(AppRadius.xl)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .strokeBorder(isSelected ? color : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 개시마감 리스트 아이템
private struct CloseDeptListItem: View {
    var entry: Detail1

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: statusIcon)
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

            Text(statusLabel)
                .font(AppFont.captionSmall)
                .fontWeight(.medium)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(AppColor.closeDeptStatus(entry.closegb).opacity(0.12))
                .foregroundColor(AppColor.closeDeptStatus(entry.closegb))
                .cornerRadius(AppRadius.sm)
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    private var statusIcon: String {
        switch entry.closegb {
        case "0": return "play.circle.fill"
        case "1": return "clock.fill"
        case "2": return "checkmark.circle.fill"
        case "3": return "lock.fill"
        default:  return "circle"
        }
    }

    private var statusLabel: String {
        switch entry.closegb {
        case "0": return "개시"
        case "1": return "가마감"
        case "2": return "마감"
        case "3": return "완료"
        default:  return "미개시"
        }
    }
}

#Preview{
    CloseDeptListViewIOS()
        .environmentObject(ViewModel())
}
