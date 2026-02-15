//
//  SortAndFilterBar.swift
//  MobileAdmin
//
//  정렬 상태 표시 및 필터 옵션 바
//

import SwiftUI

struct SortAndFilterBar: View {
    @Binding var sortConfiguration: SortConfiguration
    var filterCount: Int = 0
    var onSortChange: ((SortField) -> Void)? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // 현재 정렬 정보 표시
            Menu {
                Picker("정렬 필드", selection: Binding(
                    get: { sortConfiguration.field },
                    set: { newField in
                        sortConfiguration.setField(newField)
                        onSortChange?(newField)
                    }
                )) {
                    ForEach(SortField.allCases, id: \.self) { field in
                        HStack {
                            Image(systemName: field.systemImage)
                            Text(field.displayName)
                        }
                        .tag(field)
                    }
                }

                Divider()

                Button(action: {
                    sortConfiguration.toggleDirection()
                }) {
                    HStack {
                        Image(systemName: sortConfiguration.direction.systemImage)
                        Text(sortConfiguration.direction.displayName)
                    }
                }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(AppFont.caption)
                    Text(sortConfiguration.field.displayName)
                        .font(AppFont.caption)
                        .lineLimit(1)
                    Image(systemName: sortConfiguration.direction.systemImage)
                        .font(AppFont.caption)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(AppRadius.sm)
            }

            Spacer()

            // 필터 개수 배지 (필요시 표시)
            if filterCount > 0 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(AppFont.caption)
                        .foregroundColor(.orange)
                    Text("\(filterCount)")
                        .font(AppFont.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(AppRadius.sm)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

#Preview {
    VStack(spacing: 12) {
        SortAndFilterBar(
            sortConfiguration: .constant(.default),
            filterCount: 0
        )

        SortAndFilterBar(
            sortConfiguration: .constant(SortConfiguration(field: .frequency, direction: .descending)),
            filterCount: 2
        )
    }
    .padding()
}
