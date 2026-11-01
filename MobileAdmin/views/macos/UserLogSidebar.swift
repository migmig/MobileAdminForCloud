//
//  UserLogSidebar.swift
//  MobileAdmin
//
//  macOS 사용자 로그 콘텐츠 컬럼 — 입력 폼, 시작하면 상세 컬럼에 실시간 로그 표시
//

import SwiftUI

struct UserLogSidebar: View {
    @Binding var target: UserLogTarget?

    @StateObject private var download = FileDownloadModel()
    @State private var numberText = ""
    @AppStorage("userLog.base") private var baseRaw = ""
    @AppStorage("userLog.lines") private var initialLines = UserLogTarget.defaultLines

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("사용자 번호를 입력하고 시작하면 오른쪽에 실시간 로그가 표시됩니다.")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)

                UserLogForm(numberText: $numberText,
                            base: $baseRaw.nasLogBase,
                            initialLines: $initialLines,
                            isStreaming: target != nil,
                            isDownloading: download.isDownloading,
                            onStart: { target = $0 },
                            onDownload: downloadAll)

                if download.hasStatus {
                    DownloadStatusView(model: download)
                }

                if let target {
                    Divider()
                    HStack {
                        Label(target.number.fileName, systemImage: "dot.radiowaves.left.and.right")
                            .font(AppFont.caption)
                        Spacer()
                        Button("닫기") { self.target = nil }
                            .controlSize(.small)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle(SlidebarItem.userLogTail.title)
        .onAppear {
            if numberText.isEmpty, let target {
                numberText = String(target.number.value)
            }
        }
    }

    private func downloadAll(_ number: UserLogNumber, _ base: NasLogBase?) {
        download.start {
            try await OpsServices.userLog.downloadUserLog(String(number.value), base: base)
        }
    }
}
