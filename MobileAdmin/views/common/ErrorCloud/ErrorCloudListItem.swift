import SwiftUI

struct ErrorCloudListItem: View {
    let errorCloudItem: ErrorCloudItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // MARK: - 1. Main Error Message & Icon
            HStack(alignment: .top, spacing: 10) {
                // 에러 아이콘 강조 (빨간색 또는 .secondary)
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColor.error) // 에러 강조
                    .font(AppFont.sectionTitle) // 아이콘 크기
                    .accessibilityHidden(true) // VoiceOver 중복 방지
                
                // 에러 메시지 (가장 중요)
                Text(errorCloudItem.description ?? errorCloudItem.msg ?? "Unknown Error")
                    .font(AppFont.listTitle) // 제목 폰트로 강조
                    .lineLimit(2) // 2줄로 제한
                    .truncationMode(.tail)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.top, 5) // 상단 여백 추가
            
            // MARK: - 2. Metadata (Date & User ID)
            HStack {
                // 등록 날짜 (왼쪽 정렬)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(Util.formattedDate(errorCloudItem.registerDt ?? "").prefix(19))
                        .font(.caption)
                        .monospacedDigit() // 시간을 깔끔하게 정렬
                }
                .foregroundColor(.secondary)
                
                Spacer() // 날짜와 사용자 ID를 양쪽 끝으로 분리

                // 사용자 ID (오른쪽 정렬)
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.caption2)
                    Text(errorCloudItem.userId ?? "N/A")
                        .font(.caption)
                        .fontWeight(.medium) // 사용자 ID 살짝 강조
                }
                .foregroundColor(.gray)
            }
            .padding(.bottom, 5) // 하단 여백 추가
        }
        .padding(.vertical, 4) // 전체 항목 세로 패딩
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
