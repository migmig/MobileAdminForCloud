//
//  SearchArea.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/4/24.
//

import SwiftUI

struct SearchArea: View {
    @Binding var dateFrom : Date
    @Binding var dateTo : Date
    @Binding var isLoading:Bool
    var clearAction:()->Void
    var escaping:()  async  -> Void = {}
    var body: some View {
        HStack{
            VStack(alignment:.trailing){
                KorDatePicker("시작일", selection: $dateFrom, displayedComponents: .date)
                KorDatePicker("종료일", selection: $dateTo, displayedComponents: .date)
            }
            VStack(alignment:.leading){
                Button("조  회",systemImage:"magnifyingglass"){
                    Task{
                        isLoading = true;
                        await escaping()
                        isLoading = false;
                    }
                }
//                .font(.caption)
                .buttonStyle(.bordered)
                Button("초기화", systemImage:"arrow.clockwise"){
                    dateFrom = Date()
                    dateTo = Date()
                    clearAction()
                }
               // .font(.caption)
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview(
    traits: .fixedLayout(width:400,height:200)
) {
    SearchArea(dateFrom: .constant(Date()),
               dateTo: .constant(Date()),
               isLoading: .constant(false),
               clearAction: {}
    )
}
