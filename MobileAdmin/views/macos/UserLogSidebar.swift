//
//  UserLogSidebar.swift
//  MobileAdmin
//
//  macOS 사용자 로그 콘텐츠 컬럼 — 입력 폼, 흐름 분석 또는 실시간 보기를 시작하면 상세 컬럼에 표시
//

import SwiftUI

struct UserLogSidebar: View {
    @Binding var target: UserLogTarget?
    @Binding var timelineRequest: UserLogTimelineRequest?

    @StateObject private var download = FileDownloadModel()
    @State private var numberText = ""
    @AppStorage("userLog.base") private var baseRaw = ""
    @AppStorage("userLog.lines") private var initialLines = UserLogTarget.defaultLines
    @AppStorage(UserLogViewMode.storageKey) private var mode: UserLogViewMode = .timeline

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("사용자 번호를 입력하고 흐름 분석 또는 실시간 보기를 시작하세요.")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)

                UserLogForm(numberText: $numberText,
                            base: $baseRaw.nasLogBase,
                            initialLines: $initialLines,
                            isStreaming: target != nil,
                            isDownloading: download.isDownloading,
                            onStart: {
                                target = $0
                                mode = .stream
                            },
                            onAnalyze: { number, base in
                                timelineRequest = UserLogTimelineRequest(number: number, base: base)
                                mode = .timeline
                            },
                            onDownload: downloadAll)

                if download.hasStatus {
                    DownloadStatusView(model: download)
                }

                if timelineRequest != nil || target != nil {
                    Divider()
                }
                if let timelineRequest {
                    activeRow(timelineRequest.number.fileName,
                              systemImage: "point.3.connected.trianglepath.dotted",
                              mode: .timeline) {
                        self.timelineRequest = nil
                    }
                }
                if let target {
                    activeRow(target.number.fileName,
                              systemImage: "dot.radiowaves.left.and.right",
                              mode: .stream) {
                        self.target = nil
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle(SlidebarItem.userLogTail.title)
        .onAppear {
            if numberText.isEmpty, let number = timelineRequest?.number ?? target?.number {
                numberText = String(number.value)
            }
        }
    }

    /// 진행 중인 대상 — 누르면 해당 보기로 전환
    private func activeRow(_ fileName: String, systemImage: String, mode rowMode: UserLogViewMode,
                           onClose: @escaping () -> Void) -> some View {
        HStack {
            Button {
                mode = rowMode
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(rowMode.title)
                            .font(AppFont.captionSmall)
                            .foregroundStyle(.secondary)
                        Text(fileName)
                            .font(AppFont.caption)
                    }
                } icon: {
                    Image(systemName: systemImage)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button("닫기", action: onClose)
                .controlSize(.small)
        }
    }

    private func downloadAll(_ number: UserLogNumber, _ base: NasLogBase?) {
        download.start {
            try await OpsServices.userLog.downloadUserLog(String(number.value), base: base)
        }
    }
}
