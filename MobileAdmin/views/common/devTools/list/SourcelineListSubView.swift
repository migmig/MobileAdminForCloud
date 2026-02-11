//
//  SourcePipelineListSubView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/22/25.
//
import SwiftUI

struct SourcelineListSubView: View {
    var itemNm:String

    private var isProd: Bool { itemNm.contains("prod") }
    private var envColor: Color { isProd ? AppColor.envType("prod") : AppColor.envType("dev") }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: isProd ? Util.getDevTypeImg("prod") : Util.getDevTypeImg("dev"))
                .foregroundColor(.white)
                .font(.caption)
                .frame(width: AppIconSize.sm, height: AppIconSize.sm)
                .background(envColor.gradient)
                .cornerRadius(AppRadius.xs)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(itemNm)
                    .font(AppFont.listTitle)
                Text(isProd ? "운영" : "개발")
                    .font(AppFont.captionSmall)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xxs)
    }
}

#Preview{
    SourcelineListSubView(itemNm:"itemName")
}
