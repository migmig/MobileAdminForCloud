//
//  CloseDeptSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 12/23/24.
//

import SwiftUI

struct CloseDeptSidebar: View {
    @EnvironmentObject var closeDeptViewModel: CloseDeptViewModel
    @Binding var list:[Detail1]
    @Binding var selectedCloseDept:Detail1?
    @State var closeGb = "4"
    @State var searchText:String = ""

    var filteredList: [Detail1] {
        list.filter {
            (searchText.isEmpty || $0.deptprtnm?.localizedStandardContains(searchText) == true) &&
            (closeGb == "4" || $0.closegb == closeGb)
        }
    }

    private func loadData() async {
       let closeInfo = await closeDeptViewModel.fetchCloseDeptList()
       list = closeInfo.detail1
   }

    private func count(for code: String) -> Int {
        code == "4" ? list.count : list.filter { $0.closegb == code }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(CloseDeptStatus.filtersWithAfterClose, id: \.code) { filter in
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
            List(selection: $selectedCloseDept){
                ForEach(filteredList, id:\.self){ entry in
                    NavigationLink(value:entry){
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: CloseDeptStatus.icon(for: entry.closegb))
                                .foregroundColor(AppColor.closeDeptStatus(entry.closegb))
                            Text(entry.deptprtnm ?? "")
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
                    }
                }
            }
            .searchable(text: $searchText)
        }
        .navigationTitle("지점별 개시 마감 조회")
        #if os(macOS)
        .navigationSubtitle("\(filteredList.count) 건 조회")
        #endif
        .onAppear(){
            Task{
                await loadData()
            }
        }
    }
}
 
#Preview {
    CloseDeptSidebar(
        list: .constant([]),
        selectedCloseDept: .constant(nil)
    )
    .environmentObject(CloseDeptViewModel())
}
