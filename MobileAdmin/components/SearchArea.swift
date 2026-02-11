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
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("시작일")
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                    KorDatePicker("", selection: $dateFrom, displayedComponents: .date)
                        .labelsHidden()
                }

                Image(systemName: "arrow.right")
                    .font(AppFont.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("종료일")
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                    KorDatePicker("", selection: $dateTo, displayedComponents: .date)
                        .labelsHidden()
                }
            }

            HStack(spacing: AppSpacing.sm) {
                Button(action: {
                    Task{
                        isLoading = true;
                        await escaping()
                        isLoading = false;
                    }
                }) {
                    Label("조회", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button(action: {
                    dateFrom = Date()
                    dateTo = Date()
                    clearAction()
                }) {
                    Label("초기화", systemImage: "gobackward")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(AppSpacing.md)
        .cardBackground()
        .cornerRadius(AppRadius.lg)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
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
