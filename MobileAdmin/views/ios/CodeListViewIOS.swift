//
//  CodeListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//

import SwiftUI

struct CodeListViewIOS: View {
    @ObservedObject var viewModel:ViewModel
    @State var cmmnGroupCodeItems:[CmmnGroupCodeItem] = []
    @State private var isLoading = false

    var body: some View {
        List{
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Text("로딩 중...")
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            ForEach(cmmnGroupCodeItems, id:\.self){ item in
                NavigationLink(destination: CodeDetailView(viewModel: viewModel, cmmnGroupCodeItem: item)){
                    HStack(spacing: AppSpacing.md) {
                        Text(item.cmmnGroupCode)
                            .font(AppFont.mono)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColor.link.gradient)
                            .cornerRadius(AppRadius.xs)

                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(item.cmmnGroupCodeNm ?? "")
                                .font(AppFont.listTitle)
                            Text("그룹코드")
                                .font(AppFont.captionSmall)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if item.useAt == "Y" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColor.success)
                                .font(AppFont.caption)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(AppFont.caption)
                        }
                    }
                    .padding(.vertical, AppSpacing.xxs)
                }
            }
        }
        .navigationTitle("코드 조회")
        .onAppear(){
            if cmmnGroupCodeItems.isEmpty{
                Task{
                    isLoading = true
                    cmmnGroupCodeItems = await viewModel.fetchGroupCodeLists()
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    CodeListViewIOS(viewModel: ViewModel())
}
