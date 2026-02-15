import SwiftUI

struct ErrorCloudListItem: View {
    let errorCloudItem: ErrorCloudItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // 에러 메시지
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColor.error)
                    .font(AppFont.listTitle)
                    .accessibilityHidden(true)

                Text(errorCloudItem.description ?? errorCloudItem.msg ?? "Unknown Error")
                    .font(AppFont.listTitle)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.top, AppSpacing.xxs)

            // 심각도 및 발생 횟수 배지
            HStack(spacing: AppSpacing.sm) {
                let severity = errorCloudItem.severity ?? SeverityLevel.derived(from: errorCloudItem)
                SeverityBadge(severity: severity, style: .compact)

                if let count = errorCloudItem.occurrenceCount, count > 1 {
                    OccurrenceCountBadge(count: count)
                }

                Spacer()
            }
            .padding(.top, AppSpacing.xxs)

            // 메타데이터
            HStack {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "clock")
                        .font(AppFont.captionSmall)
                    Text(Util.formattedDate(errorCloudItem.registerDt ?? "").prefix(19))
                        .font(AppFont.caption)
                        .monospacedDigit()
                }
                .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "person.circle")
                        .font(AppFont.captionSmall)
                    Text(errorCloudItem.userId ?? "N/A")
                        .font(AppFont.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
            }
            .padding(.bottom, AppSpacing.xxs)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

#Preview(
"Content",
traits: .fixedLayout(width: 400, height: 500)
)
{
    List{
        ForEach(0..<10){idx in
            ErrorCloudListItem(errorCloudItem: ErrorCloudItem(
                code: "code\(idx)",
                description: "description\(idx)",
                msg: "msg\(idx)",
                registerDt : Util.getCurrentDateString(),
                requestInfo: "requestInfo",
                restUrl: "restUrl",
                traceCn: "traceCn",
                userId: "userId\(idx)"
            ))
        }
    
    }
}
