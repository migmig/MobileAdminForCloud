//
//  HomeViewForIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/15/25.
//

import SwiftUI

struct HomeViewForIOS: View {
    @EnvironmentObject var viewModel:ViewModel

    private let menuItems: [(SlidebarItem, String, Color)] = [
        (.errerlist,    "서비스 오류 로그를 조회합니다",   .red),
        (.goodsInfo,    "상품 정보 이력을 조회합니다",     .orange),
        (.codeList,     "공통코드 목록을 조회합니다",      .blue),
    ]

    var body: some View {
        NavigationStack{
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(menuItems, id: \.0) { item, desc, color in
                        NavigationLink(destination: destinationView(for: item)) {
                            HomeMenuCard(
                                title: item.title,
                                systemImage: item.img,
                                description: desc,
                                accentColor: color
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .groupedBackground()
            .navigationTitle("Home")
        }
    }

    @ViewBuilder
    private func destinationView(for item: SlidebarItem) -> some View {
        switch item {
        case .errerlist: ErrorListViewForIOS(viewModel: viewModel)
        case .goodsInfo: GoodsListViewIOS(viewModel: viewModel)
        case .codeList:  CodeListViewIOS(viewModel: viewModel)
        default: EmptyView()
        }
    }
}

// MARK: - 홈 메뉴 카드
struct HomeMenuCard: View {
    var title: String
    var systemImage: String
    var description: String
    var accentColor: Color

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: AppIconSize.lg, height: AppIconSize.lg)
                .background(accentColor.gradient)
                .cornerRadius(AppRadius.md)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFont.listTitle)
                    .foregroundColor(.primary)
                Text(description)
                    .font(AppFont.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AppFont.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.lg)
        .cardBackground()
        .cornerRadius(AppRadius.lg)
        .cardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(description)")
    }
}
 
