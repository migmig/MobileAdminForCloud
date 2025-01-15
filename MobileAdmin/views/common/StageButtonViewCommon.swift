//
//  StageButtonViewCommon.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/15/25.
//

import SwiftUI

struct StageButtonViewCommon: View {
    @Binding var searchText:String
    var body: some View {
        HStack{
           Button(action:{searchText = ""}){
               Label("전체", systemImage:"network")
                   .foregroundColor(searchText.isEmpty ? .accentColor : .gray)
           }
           .buttonStyle(.bordered)
           Button(action:{searchText = "prod"}){
               Label("운영", systemImage:"antenna.radiowaves.left.and.right")
                   .foregroundColor(searchText == "prod" ? .accentColor : .gray) 
           }
           .buttonStyle(.bordered)
           Button(action:{searchText = "dev"}){
               Label("개발", systemImage:"wrench.and.screwdriver")
                   .foregroundColor(searchText == "dev" ? .accentColor : .gray)
           }
           .buttonStyle(.bordered)
       }

    }
}

#Preview {
    StageButtonViewCommon(searchText:.constant("prod"))
}
