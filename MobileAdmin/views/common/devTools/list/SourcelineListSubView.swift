//
//  SourcePipelineListSubView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/22/25.
//
import SwiftUI

struct SourcelineListSubView: View {
    var itemNm:String
    var body: some View {
        HStack{
            Image(systemName: itemNm.contains("prod") ? Util.getDevTypeImg("prod") : Util.getDevTypeImg("dev"))
                .foregroundColor(itemNm.contains("prod") ? AppColor.envType("prod") : AppColor.envType("dev"))
            Text(itemNm)
        }
    }
}

#Preview{
    SourcelineListSubView(itemNm:"itemName")
}
