//
//  SourcePipelineListSubView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/22/25.
//
import SwiftUI

struct SourcelineListSubView: View {
    var itemNm:String

    private var env: SourceEnvType { SourceEnvType.of(itemNm) }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: env.iconName)
                .foregroundColor(.white)
                .font(.caption)
                .frame(width: AppIconSize.sm, height: AppIconSize.sm)
                .background(env.color.gradient)
                .cornerRadius(AppRadius.xs)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(itemNm)
                    .font(AppFont.listTitle)
                Text(env.title)
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
