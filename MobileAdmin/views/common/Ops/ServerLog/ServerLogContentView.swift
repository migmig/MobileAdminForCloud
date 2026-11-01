//
//  ServerLogContentView.swift
//  MobileAdmin
//
//  서버 로그 파일 내용 (마지막 N줄) — iOS 드릴다운 마지막 화면 / macOS 상세 컬럼 공용
//

import SwiftUI

struct ServerLogContentView: View {
    let ref: ServerLogFileRef

    @StateObject private var model = ServerLogContentModel()
    @StateObject private var download = FileDownloadModel()
    @AppStorage("serverLog.tail") private var tail = ServerLogService.defaultTail

    private struct LoadKey: Hashable {
        let ref: ServerLogFileRef
        let tail: Int
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            Divider()
            contentArea
        }
        .navigationTitle(ref.entry.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: LoadKey(ref: ref, tail: tail)) {
            await model.load(ref, tail: tail)
        }
        .onChange(of: ref) { _, _ in
            download.reset()
        }
    }

    // MARK: - 헤더

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: ref.kind.systemImage)
                Text(ref.base.map { "\(ref.kind.title) · \($0.title)" } ?? ref.kind.title)
            }
            .font(AppFont.caption)
            .foregroundStyle(.secondary)

            Text(ref.displayPath)
                .font(AppFont.listTitle)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)

            HStack(spacing: AppSpacing.sm) {
                Text("\(Util.formatFileSize(ref.entry.size)) · \(Util.formatUnixTime(ref.entry.modTime))")
                    .font(AppFont.captionSmall)
                    .foregroundStyle(.secondary)
                if let content = model.content, content.truncated {
                    OpsTag(text: "최근 \(content.tailLines)줄만 표시", tint: .orange)
                }
                if ref.entry.isGzip {
                    OpsTag(text: "압축 해제하여 표시", tint: .blue)
                }
            }

            HStack(spacing: AppSpacing.sm) {
                Picker("표시 줄 수", selection: $tail) {
                    ForEach(ServerLogService.tailOptions, id: \.self) { option in
                        Text("\(option)줄").tag(option)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()

                Spacer()

                Button {
                    Task { await model.load(ref, tail: tail) }
                } label: {
                    Label("다시 읽기", systemImage: "arrow.clockwise")
                }
                .disabled(model.isLoading)

                Button {
                    let ref = ref
                    download.start { try await OpsServices.serverLog.download(ref) }
                } label: {
                    Label("다운로드", systemImage: "square.and.arrow.down")
                }
                .disabled(download.isDownloading)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if download.hasStatus {
                DownloadStatusView(model: download)
            }
        }
    }

    // MARK: - 본문

    @ViewBuilder
    private var contentArea: some View {
        if let content = model.content {
            VStack(spacing: 0) {
                if let error = model.error {
                    OpsBanner.error(error)
                        .padding(AppSpacing.sm)
                }
                LogViewerPanel(lines: content.lines, emptyTitle: "빈 파일입니다")
                    .overlay(alignment: .top) {
                        if model.isLoading {
                            ProgressView()
                                .padding(AppSpacing.sm)
                                .background(.regularMaterial, in: Capsule())
                                .padding(.top, AppSpacing.xxl)
                        }
                    }
            }
        } else if let error = model.error {
            OpsErrorView(error: error) {
                Task { await model.load(ref, tail: tail) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ProgressView("불러오는 중...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
