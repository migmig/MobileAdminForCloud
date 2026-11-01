//
//  UploadBrowserViewIOS.swift
//  MobileAdmin
//
//  iOS 업로드 브라우저 — 디렉터리마다 화면을 push하는 재귀 구조, 파일은 Quick Look
//

import SwiftUI
import QuickLook

struct UploadBrowserViewIOS: View {
    @StateObject private var model: UploadBrowserModel
    @StateObject private var opener = UploadFileOpener()

    init(path: UploadPath = .root) {
        _model = StateObject(wrappedValue: UploadBrowserModel(path: path))
    }

    var body: some View {
        let entries = model.visibleEntries
        List {
            if let error = model.error, model.response != nil {
                OpsBanner.error(error)
            }
            ForEach(entries) { entry in
                row(for: entry)
            }
        }
        .searchable(text: $model.filter, prompt: "이름 필터")
        .overlay {
            if model.response == nil {
                if let error = model.error {
                    OpsErrorView(error: error) {
                        Task { await model.load() }
                    }
                } else {
                    ProgressView("불러오는 중...")
                }
            } else if entries.isEmpty {
                EmptyStateView(systemImage: "folder",
                               title: model.filter.isEmpty ? "비어 있는 폴더입니다" : "일치하는 항목이 없습니다")
            }
        }
        .toolbar {
            ToolbarItem {
                UploadSortMenu(sort: $model.sort, ascending: $model.ascending)
            }
        }
        .refreshable { await model.load() }
        .task {
            if model.response == nil { await model.load() }
        }
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
        .navigationTitle(model.path.lastName ?? SlidebarItem.uploadBrowser.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private func row(for entry: UploadEntry) -> some View {
        if entry.isDir {
            NavigationLink {
                UploadBrowserViewIOS(path: model.path.appending(entry.name))
            } label: {
                FileEntryRow(upload: entry)
            }
        } else {
            let ref = UploadEntryRef(directory: model.path, entry: entry)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Button {
                    if opener.loadingRef == ref {
                        opener.cancel()
                    } else {
                        opener.request(ref)
                    }
                } label: {
                    FileEntryRow(upload: entry) {
                        if opener.loadingRef == ref {
                            HStack(spacing: AppSpacing.xs) {
                                ProgressView().controlSize(.small)
                                Text("취소")
                                    .font(AppFont.caption)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                if let message = opener.failureMessage(for: ref) {
                    Text(message)
                        .font(AppFont.captionSmall)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var confirmTitle: String {
        let size = opener.pendingConfirmation.map { Util.formatFileSize($0.entry.size) } ?? ""
        return "\(size) 파일을 내려받을까요?"
    }
}

#Preview {
    NavigationStack {
        UploadBrowserViewIOS()
    }
}
