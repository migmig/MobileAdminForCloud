//
//  UploadFileDetailView.swift
//  MobileAdmin
//
//  업로드 파일 상세 (macOS 상세 컬럼) — 정보, Quick Look, 다운로드 폴더에 저장
//

import SwiftUI
import QuickLook

struct UploadFileDetailView: View {
    let ref: UploadEntryRef

    @StateObject private var opener = UploadFileOpener()
    @StateObject private var saver = FileDownloadModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                infoCard
                actions
                if opener.loadingRef == ref {
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView().controlSize(.small)
                        Text("파일을 받는 중...")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                        Button("취소") { opener.cancel() }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                    }
                }
                if let message = opener.failureMessage(for: ref) {
                    OpsBanner(systemImage: "exclamationmark.triangle", text: message, tint: .red)
                }
                if saver.hasStatus {
                    DownloadStatusView(model: saver)
                }
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle(ref.entry.name)
        .confirmationDialog(confirmTitle,
                            isPresented: Binding(get: { opener.pendingConfirmation != nil },
                                                 set: { if !$0 { opener.pendingConfirmation = nil } }),
                            titleVisibility: .visible) {
            Button("내려받기") {
                if let pending = opener.pendingConfirmation { opener.open(pending) }
            }
            Button("취소", role: .cancel) {}
        }
        .quickLookPreview($opener.previewURL)
    }

    private var header: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: ref.entry.fileKind.systemImage)
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(ref.entry.name)
                    .font(AppFont.sectionTitle)
                    .textSelection(.enabled)
                Text("/" + ref.directory.string)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            InfoRow(title: "경로", value: "/" + ref.path.string)
            Divider()
            InfoRow(title: "크기", value: "\(Util.formatFileSize(ref.entry.size)) (\(ref.entry.size) bytes)")
            Divider()
            InfoRow(title: "수정 시각", value: Util.formatUnixTime(ref.entry.modTime))
            Divider()
            InfoRow(title: "종류", value: ref.entry.fileKind.title)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .cardBackground()
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    private var actions: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                opener.request(ref)
            } label: {
                Label("Quick Look", systemImage: "eye")
            }
            .buttonStyle(.borderedProminent)
            .disabled(opener.loadingRef != nil)

            #if os(macOS)
            Button {
                let ref = ref
                saver.start {
                    let cached = try await OpsServices.upload.fetchFile(ref)
                    return try DownloadStore.copyToDownloads(cached)
                }
            } label: {
                Label("다운로드 폴더에 저장", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            .disabled(saver.isDownloading)
            #endif
        }
    }

    private var confirmTitle: String {
        let size = opener.pendingConfirmation.map { Util.formatFileSize($0.entry.size) } ?? ""
        return "\(size) 파일을 내려받을까요?"
    }
}
