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
               Label("전체", systemImage:"gear")
           }
           .buttonStyle(.bordered)
           .foregroundColor(searchText.isEmpty ? .accentColor : .gray)
           Button(action:{searchText = "prod"}){
               Label("운영", systemImage:"gear")
           }
           .buttonStyle(.bordered)
           .foregroundColor(searchText == "prod" ? .accentColor : .gray)
           Button(action:{searchText = "dev"}){
               Label("개발", systemImage:"gear")
           }
           .buttonStyle(.bordered)
           .foregroundColor(searchText == "dev" ? .accentColor : .gray)
       }

    }
}

#Preview {
    StageButtonViewCommon(searchText:.constant("prod"))
}
