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
        VStack{
            InfoRow(title: "부서코드"    ,value: closeDetail?.deptcd)
            Divider()
            InfoRow(title: "부서명"      ,value: closeDetail?.deptprtnm)
            Divider()
            InfoRow(title: "개시구분코드",value: closeDetail?.closegb)
            Divider()
            InfoRow(title: "개시구분명"  ,value: closeDetail?.rmk)
            Divider()
            InfoRow2(title: "개시시각"){
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
            Divider()
            if (closeDetail?.closetime == "") {
                Text(" ")
            }else {
                InfoRow2(title: "마감시각"){
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
                Divider()
            }
        }
        .navigationBarTitle(closeDetail?.deptprtnm ?? "부서코드")
        .padding()
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
