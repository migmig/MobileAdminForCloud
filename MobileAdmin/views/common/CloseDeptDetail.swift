//
//  CloseDeptDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 12/23/24.
//

import SwiftUI

struct CloseDeptDetail: View {
    var closeDetail:Detail1?

    private var statusColor: Color {
        AppColor.closeDeptStatus(closeDetail?.closegb)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // MARK: - 상태 헤더
                statusHeader

                // MARK: - 진행 타임라인
                CloseDeptTimeline(closegb: closeDetail?.closegb)
                    .padding(.horizontal, AppSpacing.xs)

                // MARK: - 부서 정보
                CardView(title: "부서 정보", systemImage: "building.2") {
                    InfoRow(title: "부서코드", value: closeDetail?.deptcd)
                    InfoRow(title: "부서명",   value: closeDetail?.deptprtnm)
                }

                // MARK: - 시간 정보
                CardView(title: "시간 정보", systemImage: "clock") {
                    timeRow(
                        icon: "play.circle.fill",
                        label: "개시시각",
                        time: closeDetail?.opentime,
                        color: AppColor.closeDeptStatus("0")
                    )
                    if let closetime = closeDetail?.closetime, !closetime.isEmpty {
                        Divider()
                        timeRow(
                            icon: "checkmark.circle.fill",
                            label: "마감시각",
                            time: closetime,
                            color: AppColor.closeDeptStatus("2")
                        )
                    }
                }
            }
            .padding()
        }
        #if os(iOS)
        .navigationBarTitle(closeDetail?.deptprtnm ?? "부서코드")
        #endif
    }

    // MARK: - 상태 헤더
    private var statusHeader: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: CloseDeptStatus.icon(for: closeDetail?.closegb))
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: AppIconSize.lg, height: AppIconSize.lg)
                .background(statusColor.opacity(0.12))
                .cornerRadius(AppRadius.md)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(closeDetail?.deptprtnm ?? "")
                    .font(AppFont.sectionTitle)
                    .fontWeight(.semibold)
                HStack(spacing: AppSpacing.xs) {
                    Text(CloseDeptStatus.label(for: closeDetail?.closegb))
                        .font(AppFont.captionSmall)
                        .fontWeight(.semibold)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(statusColor.opacity(0.15))
                        .foregroundColor(statusColor)
                        .cornerRadius(AppRadius.sm)
                    if let deptcd = closeDetail?.deptcd {
                        Text(deptcd)
                            .font(AppFont.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .cardBackground()
        .cornerRadius(AppRadius.lg)
    }

    // MARK: - 시간 행
    private func timeRow(icon: String, label: String, time: String?, color: Color) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: AppIconSize.sm)
            Text(label)
                .font(AppFont.body)
                .foregroundColor(.secondary)
            Spacer()
            Text(formatTime(time))
                .font(.system(.body, design: .rounded).bold())
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    private func formatTime(_ time: String?) -> String {
        guard let t = time, t.count >= 6 else { return "--:--" }
        let h = t.prefix(2)
        let m = t.dropFirst(2).prefix(2)
        let s = t.dropFirst(4).prefix(2)
        return "\(h):\(m):\(s)"
    }
}

// MARK: - 진행 타임라인
private struct CloseDeptTimeline: View {
    var closegb: String?

    private var currentStep: Int {
        switch closegb {
        case "0": return 1 // 개시
        case "1": return 2 // 가마감
        case "2": return 3 // 마감
        case "3": return 3 // 마감후거래
        default:  return 0 // 미개시
        }
    }

    private let steps = [
        ("circle.dashed",          "미개시"),
        ("play.circle.fill",       "개시"),
        ("clock.fill",             "가마감"),
        ("checkmark.circle.fill",  "마감"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                // 단계 원
                VStack(spacing: AppSpacing.xxs) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep
                                  ? AppColor.closeDeptStatus(stepCode(index)).opacity(0.15)
                                  : Color.secondary.opacity(0.08))
                            .frame(width: 32, height: 32)
                        Image(systemName: step.0)
                            .font(.system(.caption, weight: index <= currentStep ? .bold : .regular))
                            .foregroundColor(index <= currentStep
                                             ? AppColor.closeDeptStatus(stepCode(index))
                                             : .secondary.opacity(0.4))
                    }
                    Text(step.1)
                        .font(.system(.caption2))
                        .foregroundColor(index <= currentStep ? .primary : .secondary.opacity(0.5))
                }

                // 연결선
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep
                              ? AppColor.closeDeptStatus(stepCode(index + 1))
                              : Color.secondary.opacity(0.15))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, AppSpacing.lg)
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .cardBackground()
        .cornerRadius(AppRadius.lg)
    }

    private func stepCode(_ index: Int) -> String {
        switch index {
        case 0: return ""
        case 1: return "0"
        case 2: return "1"
        case 3: return "2"
        default: return ""
        }
    }
}

#Preview {
    CloseDeptDetail(
        closeDetail: Detail1(
            closeempno: "",
            rmk: "개시",
            deptprtnm: "수원",
            closegb: "0",
            closetime: "",
            opentime: "080101",
            deptcd: "100400"
        )
    )
}
