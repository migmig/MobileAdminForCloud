//
//  CloseDeptDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 12/23/24.
//

import SwiftUI

struct CloseDeptDetail: View {
    var closeDetail:Detail1?
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                CardView(title: "부서 정보", systemImage: "building.2") {
                    InfoRow(title: "부서코드"    ,value: closeDetail?.deptcd)
                    InfoRow(title: "부서명"      ,value: closeDetail?.deptprtnm)
                    InfoRow(title: "개시구분코드",value: closeDetail?.closegb)
                    InfoRow(title: "개시구분명"  ,value: closeDetail?.rmk)
                }

                CardView(title: "개시시각", systemImage: "clock") {
                    KorDatePicker(
                        "",
                        selection:
                                .constant(
                                    Util
                                        .combineTodayWithTime(
                                            closeDetail?.opentime ?? ""
                                        ) ?? Date()
                                ),
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                }

                if (closeDetail?.closetime != "") {
                    CardView(title: "마감시각", systemImage: "clock.badge.checkmark") {
                        KorDatePicker(
                            "",
                            selection:
                                    .constant(
                                        Util
                                            .combineTodayWithTime(
                                                closeDetail?.closetime ?? ""
                                            ) ?? Date()
                                    ),
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                    }
                }
            }
            .padding()
        }
        #if os(iOS)
        .navigationBarTitle(closeDetail?.deptprtnm ?? "부서코드")
        #endif
    }
}

#Preview {
    CloseDeptDetail(
        closeDetail: Detail1(
            closeempno: "",
            rmk: "개시",
            deptprtnm: "수원",
            closegb: "0",
            closetime: "",
            opentime: "080101",
            deptcd: "100400"
        )
    )
}
