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
                KorDatePicker("From", selection: $dateFrom, displayedComponents: .date)
                KorDatePicker("To", selection: $dateTo, displayedComponents: .date)
            }
            VStack(alignment:.leading){
                Button("조회", systemImage: "magnifyingglass"){
                    Task{
                        isLoading = true;
                        await escaping()
                        isLoading = false;
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                Button("초기화", systemImage:"arrow.clockwise"){
                    dateFrom = Date()
                    dateTo = Date()
                    clearAction()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    SearchArea(dateFrom: .constant(Date()),
               dateTo: .constant(Date()),
               isLoading: .constant(false),
               clearAction: {}
    )
}
