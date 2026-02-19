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

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(errorCloudItem.description ?? errorCloudItem.msg ?? "Unknown Error")
                        .font(AppFont.listTitle)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .foregroundColor(.primary)

                    // REST URL
                    if let restUrl = errorCloudItem.restUrl, !restUrl.isEmpty {
                        Text(restUrl)
                            .font(AppFont.mono)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.top, AppSpacing.xxs)

            // 하단 메타데이터
            HStack(spacing: AppSpacing.sm) {
                // 에러 코드 태그
                if let code = errorCloudItem.code, !code.isEmpty {
                    Text(code)
                        .font(AppFont.captionSmall)
                        .fontWeight(.medium)
                        .foregroundColor(AppColor.error)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(
                            Capsule()
                                .fill(AppColor.error.opacity(0.1))
                        )
                }

                Spacer()

                // 시간
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "clock")
                        .font(AppFont.captionSmall)
                    Text(Util.formattedDate(errorCloudItem.registerDt ?? "").prefix(19))
                        .font(AppFont.caption)
                        .monospacedDigit()
                }
                .foregroundColor(.secondary)

                // 사용자
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
                code: "ERR_\(idx)0\(idx)",
                description: "NullPointerException: Cannot invoke method on null object reference at UserService.getUser",
                msg: "msg\(idx)",
                registerDt : Util.getCurrentDateString(),
                requestInfo: "requestInfo",
                restUrl: "/api/v1/admin/users/findByEmail",
                traceCn: "traceCn",
                userId: "userId\(idx)"
            ))
        }

    }
}
