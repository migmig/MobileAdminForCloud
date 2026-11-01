//
//  ServerLogFileListViewIOS.swift
//  MobileAdmin
//
//  iOS 서버 로그 3단계 — 파일 목록 (최신순, 이름 필터)
//

import SwiftUI

struct ServerLogFileListViewIOS: View {
    let kind: ServerLogKind
    let base: NasLogBase?
    /// nil = 루트
    let folder: String?

    @StateObject private var model = ServerLogListModel()
    @State private var filter = ""

    var body: some View {
        let files = model.filteredFiles(filter)
        List {
            if let basePath = model.files?.base, NasLogBase.isLocalFallback(basePath) {
                OpsBanner.nasFallback(basePath: basePath)
            }
            if let error = model.filesError, model.files != nil {
                OpsBanner.error(error)
            }
            ForEach(files) { file in
                NavigationLink {
                    ServerLogContentView(ref: ServerLogFileRef(kind: kind, base: base, folder: folder, entry: file))
                } label: {
                    FileEntryRow(logFile: file)
                }
            }
        }
        .searchable(text: $filter, prompt: "파일 이름")
        .overlay {
            if model.files == nil {
                if let error = model.filesError {
                    OpsErrorView(error: error) {
                        Task { await load() }
                    }
                } else {
                    ProgressView("불러오는 중...")
                }
            } else if files.isEmpty {
                EmptyStateView(systemImage: "doc.text.magnifyingglass",
                               title: filter.isEmpty ? "파일이 없습니다" : "일치하는 파일이 없습니다")
            }
        }
        .refreshable { await load() }
        .task {
            if model.files == nil { await load() }
        }
        .navigationTitle(folder ?? "(루트)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func load() async {
        await model.loadFiles(kind: kind, base: base, folder: folder)
    }
}
