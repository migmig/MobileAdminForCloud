//
//  MultiSelectToggle.swift
//  MobileAdmin
//
//  다중 선택 모드 토글 컴포넌트
//

import SwiftUI

struct MultiSelectToggle: View {
    @Binding var isMultiSelectMode: Bool
    var selectedCount: Int = 0

    var body: some View {
        Button(action: {
            withAnimation {
                isMultiSelectMode.toggle()
                // 모드 종료 시 선택 초기화는 부모에서 처리
            }
        }) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "circle")
                    .font(AppFont.caption)
                    .foregroundColor(isMultiSelectMode ? .blue : .secondary)

                if isMultiSelectMode && selectedCount > 0 {
                    Text("\(selectedCount)개 선택")
                        .font(AppFont.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(isMultiSelectMode ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(AppRadius.sm)
        }
        .accessibilityLabel(isMultiSelectMode ? "다중 선택 모드 활성" : "다중 선택 모드 비활성")
        .accessibilityValue("\(selectedCount)개 선택됨")
    }
}

#Preview {
    VStack(spacing: 12) {
        MultiSelectToggle(isMultiSelectMode: .constant(false), selectedCount: 0)
        MultiSelectToggle(isMultiSelectMode: .constant(true), selectedCount: 3)
        MultiSelectToggle(isMultiSelectMode: .constant(true), selectedCount: 0)
    }
    .padding()
}
