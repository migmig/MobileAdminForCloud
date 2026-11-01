//
//  DownloadedFileActions.swift
//  MobileAdmin
//
//  파일 다운로드 상태 모델과 완료 후 동작(미리보기/공유/열기/Finder) 뷰
//

import SwiftUI
import QuickLook
#if os(macOS)
import AppKit
#endif

// MARK: - 다운로드 상태 모델

@MainActor
final class FileDownloadModel: ObservableObject {
    @Published private(set) var fileURL: URL?
    @Published private(set) var isDownloading = false
    @Published private(set) var error: Error?

    private var task: Task<Void, Never>?
    private var generation = 0

    /// 표시할 상태(진행 중 / 완료 / 실패)가 있는지
    var hasStatus: Bool { isDownloading || fileURL != nil || error != nil }

    /// 다운로드 실행 — 진행 중인 작업은 취소하고 새로 시작한다
    func start(_ operation: @escaping () async throws -> URL) {
        task?.cancel()
        generation += 1
        let current = generation
        fileURL = nil
        error = nil
        isDownloading = true
        task = Task {
            do {
                let url = try await operation()
                guard current == generation else { return }
                fileURL = url
            } catch {
                guard current == generation else { return }
                if !OpsError.isCancellation(error) {
                    self.error = error
                }
            }
            if current == generation {
                isDownloading = false
            }
        }
    }

    func cancel() {
        task?.cancel()
        generation += 1
        isDownloading = false
    }

    func reset() {
        cancel()
        fileURL = nil
        error = nil
    }
}

// MARK: - 다운로드 상태 표시

/// 진행 중 / 완료(동작 버튼) / 실패를 한 줄로 표시. 아무 상태도 없으면 비어 있다.
struct DownloadStatusView: View {
    @ObservedObject var model: FileDownloadModel

    var body: some View {
        if model.isDownloading {
            HStack(spacing: AppSpacing.sm) {
                ProgressView().controlSize(.small)
                Text("다운로드 중...")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("취소") { model.cancel() }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
            }
        } else if let url = model.fileURL {
            DownloadedFileActions(fileURL: url)
        } else if let error = model.error {
            OpsBanner.error(error)
        }
    }
}

// MARK: - 완료 후 동작

struct DownloadedFileActions: View {
    let fileURL: URL

    @State private var previewURL: URL?

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Label(fileURL.lastPathComponent, systemImage: "checkmark.circle.fill")
                .font(AppFont.caption)
                .foregroundStyle(.green)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: AppSpacing.sm)

            #if os(iOS)
            if FileKind.from(name: fileURL.lastPathComponent, isDirectory: false).isPreviewable {
                Button {
                    previewURL = fileURL
                } label: {
                    Label("미리보기", systemImage: "eye")
                }
            }
            ShareLink(item: fileURL) {
                Label("공유", systemImage: "square.and.arrow.up")
            }
            #elseif os(macOS)
            Button {
                NSWorkspace.shared.open(fileURL)
            } label: {
                Label("열기", systemImage: "arrow.up.forward.app")
            }
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            } label: {
                Label("Finder에서 보기", systemImage: "folder")
            }
            #endif
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .quickLookPreview($previewURL)
    }
}
