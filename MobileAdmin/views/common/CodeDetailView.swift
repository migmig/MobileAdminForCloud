//
//  CodeDetailView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//
import SwiftUI

struct CodeDetailView: View {
    @ObservedObject var viewModel: ViewModel
    var cmmnGroupCodeItem: CmmnGroupCodeItem
    @State private var isLoading: Bool = false
    @State private var cmmnCodeItems: [CmmnCodeItem] = []

    // MARK: - 동적 기타항목 컬럼
    private var activeExtraColumns: [(String, KeyPath<CmmnCodeItem, String>)] {
        let all: [(String?, KeyPath<CmmnCodeItem, String>)] = [
            (cmmnGroupCodeItem.groupEstbs1Value, \.cmmnEstbs1Value),
            (cmmnGroupCodeItem.groupEstbs2Value, \.cmmnEstbs2Value),
            (cmmnGroupCodeItem.groupEstbs3Value, \.cmmnEstbs3Value),
            (cmmnGroupCodeItem.groupEstbs4Value, \.cmmnEstbs4Value),
            (cmmnGroupCodeItem.groupEstbs5Value, \.cmmnEstbs5Value),
            (cmmnGroupCodeItem.groupEstbs6Value, \.cmmnEstbs6Value),
            (cmmnGroupCodeItem.groupEstbs7Value, \.cmmnEstbs7Value),
        ]
        return all.compactMap { header, keyPath in
            guard let name = header, !name.isEmpty else { return nil }
            return (name, keyPath)
        }
    }

    // MARK: - 기타항목 (그룹코드 레벨)
    private var extraGroupFields: [(String, String)] {
        let all: [(String, String?)] = [
            ("기타항목1", cmmnGroupCodeItem.groupEstbs1Value),
            ("기타항목2", cmmnGroupCodeItem.groupEstbs2Value),
            ("기타항목3", cmmnGroupCodeItem.groupEstbs3Value),
            ("기타항목4", cmmnGroupCodeItem.groupEstbs4Value),
            ("기타항목5", cmmnGroupCodeItem.groupEstbs5Value),
            ("기타항목6", cmmnGroupCodeItem.groupEstbs6Value),
            ("기타항목7", cmmnGroupCodeItem.groupEstbs7Value),
        ]
        return all.compactMap { title, value in
            guard let v = value, !v.isEmpty else { return nil }
            return (title, v)
        }
    }

    private func fnSearch() {
        Task {
            withAnimation { isLoading = true }
            cmmnCodeItems = await viewModel.fetchCodeListByGroupCode(cmmnGroupCodeItem.cmmnGroupCode)
            withAnimation { isLoading = false }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // MARK: - 그룹코드 헤더
                groupCodeHeader

                // MARK: - 기타항목 (값 있는 항목만)
                if !extraGroupFields.isEmpty {
                    CardView(title: "기타 항목", systemImage: "list.bullet.rectangle") {
                        ForEach(extraGroupFields, id: \.0) { title, value in
                            InfoRow(title: title, value: value)
                        }
                    }
                }

                // MARK: - 상세코드 테이블
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.vertical, AppSpacing.xl)
                } else if cmmnCodeItems.isEmpty {
                    EmptyStateView(
                        systemImage: "doc.text.magnifyingglass",
                        title: "코드 데이터 없음"
                    )
                } else {
                    codeTable
                }
            }
            .padding()
        }
        .navigationTitle("코드상세조회")
        .onAppear { fnSearch() }
        .onChange(of: cmmnGroupCodeItem) { _, _ in fnSearch() }
    }

    // MARK: - 그룹코드 헤더 카드
    private var groupCodeHeader: some View {
        HStack(spacing: AppSpacing.md) {
            Text(cmmnGroupCodeItem.cmmnGroupCode)
                .font(AppFont.mono)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColor.link.gradient)
                .cornerRadius(AppRadius.sm)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(cmmnGroupCodeItem.cmmnGroupCodeNm ?? "")
                    .font(AppFont.sectionTitle)
                    .fontWeight(.semibold)
                HStack(spacing: AppSpacing.xs) {
                    Text(UseAtStatus.label(for: cmmnGroupCodeItem.useAt))
                        .font(AppFont.captionSmall)
                        .fontWeight(.semibold)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(UseAtStatus.color(for: cmmnGroupCodeItem.useAt).opacity(0.15))
                        .foregroundColor(UseAtStatus.color(for: cmmnGroupCodeItem.useAt))
                        .cornerRadius(AppRadius.sm)
                    Text("그룹코드")
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .cardBackground()
        .cornerRadius(AppRadius.lg)
    }

    // MARK: - 상세코드 테이블
    private var codeTable: some View {
        CardView(title: "상세코드 (\(cmmnCodeItems.count)건)", systemImage: "tablecells") {
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    // 헤더
                    HStack {
                        Text("코드").frame(width: 100)
                        Text("코드명").frame(width: 200)
                        Text("사용여부").frame(width: 80)
                        ForEach(activeExtraColumns, id: \.0) { header, _ in
                            Text(header).frame(width: 150)
                        }
                    }
                    .fontWeight(.bold)
                    .font(AppFont.caption)
                    .padding(.vertical, AppSpacing.sm)
                    .tertiaryBackground()
                    .cornerRadius(AppRadius.sm)

                    Divider()

                    // 데이터 행
                    ForEach(Array(cmmnCodeItems.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text(item.cmmnCode)
                                .fontWeight(.medium)
                                .frame(width: 100)
                            Text(item.cmmnCodeNm).frame(width: 200)
                            Image(systemName: UseAtStatus.icon(for: item.useAt))
                                .foregroundColor(UseAtStatus.color(for: item.useAt))
                                .frame(width: 80)
                            ForEach(activeExtraColumns, id: \.0) { _, keyPath in
                                Text(item[keyPath: keyPath]).frame(width: 150)
                            }
                        }
                        .font(AppFont.caption)
                        .padding(.vertical, AppSpacing.xs)
                        .background(index % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05))
                    }
                }
            }
        }
    }
}

#Preview(
    traits: .fixedLayout(width: 600, height: 1200)
) {
    CodeDetailView(
        viewModel: ViewModel(),
        cmmnGroupCodeItem: CmmnGroupCodeItem(
            cmmnGroupCode: "8005",
            cmmnGroupCodeNm: "그룹코드명",
            groupEstbs1Value: "그룹코드설명",
            groupEstbs2Value: "사용여부",
            groupEstbs3Value: "등록자",
            groupEstbs4Value: "등록일",
            groupEstbs5Value: "수정자",
            groupEstbs6Value: "수정일",
            groupEstbs7Value: "수정일",
            useAt: "N"
        ))
}
