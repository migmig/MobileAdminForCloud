//
//  ExpandableRequestInfoRow.swift
//  MobileAdmin
//
//  Request Info를 펼칠 수 있는 형태로 표시하는 컴포넌트
//

import SwiftUI

struct ExpandableRequestInfoRow: View {
    let requestInfo: String
    let onCopy: () -> Void
    @State private var isExpanded = false

    var requestInfoDisplay: String {
        Util.formatRequestInfo(requestInfo)
    }

    var characterCount: Int {
        requestInfo.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header with expand/collapse toggle
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(AppFont.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16, alignment: .center)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "network")
                            .font(AppFont.caption)
                            .foregroundColor(AppColor.icon)

                        Text("Request Info")
                            .font(AppFont.listTitle)
                            .fontWeight(.medium)

                        Spacer()

                        // Character count badge
                        Text("\(characterCount) chars")
                            .font(AppFont.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(AppRadius.xs)
                    }
                }

                Spacer()

                // Copy button
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.icon)
                        .padding(AppSpacing.xs)
                }
                .buttonStyle(.plain)
                .help("Copy Request Info")
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Divider()

                    // Formatted request info with monospace font
                    ScrollView(.horizontal) {
                        Text(requestInfoDisplay)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .textSelection(.enabled)
                            .padding(AppSpacing.sm)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(AppRadius.sm)
                    }
                    .scrollIndicators(.automatic)
                }
                .padding(.top, AppSpacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

#Preview {
    VStack(spacing: 20) {
        ExpandableRequestInfoRow(
            requestInfo: "userId=user123&action=create&timestamp=2024-01-15T10:30:00Z",
            onCopy: { print("Copied!") }
        )

        ExpandableRequestInfoRow(
            requestInfo: """
            {
              "userId": "user123",
              "action": "create",
              "payload": {
                "name": "Test Item",
                "description": "A test item for demonstration"
              }
            }
            """,
            onCopy: { print("Copied!") }
        )
    }
    .padding()
}
