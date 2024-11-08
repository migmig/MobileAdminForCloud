//
//  EdcCrseDetailView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/8/24.
//

import SwiftUI

struct EdcCrseDetailView: View {
    var edcCrseClinfo : EdcCrseCl
    init(_ edcCrseClinfo:EdcCrseCl){
        self.edcCrseClinfo = edcCrseClinfo
    }
    var body: some View {
        ScrollView{
            LazyVStack{
                    
                    InfoRow(title: "강의명", value: edcCrseClinfo.edcCrseName ?? "")
                    Divider()
                    InfoRow(title: "강의설명", value: edcCrseClinfo.lctreIntrcn ?? "")
                    Divider() 
            }
            .padding()
        }
    }
}

#Preview {
    EdcCrseDetailView(EdcCrseCl(
        "강의제목",
        "강의내용 길게길게길게 "
    ))
}
