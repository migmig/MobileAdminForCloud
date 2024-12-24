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
            InfoRow(title: "개시시각"    ,value: closeDetail?.opentime)
            Divider()
            InfoRow(title: "마감시각"    ,value: closeDetail?.closetime)
        }
        .padding()
    }
}

#Preview {
    CloseDeptDetail()
}
