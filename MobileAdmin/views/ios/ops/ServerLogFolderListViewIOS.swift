//
//  ServerLogFolderListViewIOS.swift
//  MobileAdmin
//
//  iOS 서버 로그 2단계 — 폴더 목록 ("(루트)" + 월별 폴더)
//

import SwiftUI

struct ServerLogFolderListViewIOS: View {
    let kind: ServerLogKind
    let base: NasLogBase?

    @StateObject private var model = ServerLogListModel()

    var body: some View {
        List {
            if let basePath = model.folders?.base, NasLogBase.isLocalFallback(basePath) {
                OpsBanner.nasFallback(basePath: basePath)
            }
            if let error = model.foldersError, model.folders != nil {
                OpsBanner.error(error)
            }
            if let response = model.folders {
                Section {
                    NavigationLink {
                        ServerLogFileListViewIOS(kind: kind, base: base, folder: nil)
                    } label: {
                        FileEntryRow(name: "(루트)", kind: .folder, size: nil, modTime: nil)
                    }
                    ForEach(response.folders) { folder in
                        NavigationLink {
                            ServerLogFileListViewIOS(kind: kind, base: base, folder: folder.name)
                        } label: {
                            FileEntryRow(folder: folder)
                        }
                    }
                } header: {
                    Text(response.base)
                        .textCase(nil)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .overlay {
            if model.folders == nil {
                if let error = model.foldersError {
                    OpsErrorView(error: error) {
                        Task { await load() }
                    }
                } else {
                    ProgressView("불러오는 중...")
                }
            }
        }
        .refreshable { await load() }
        .task {
            if model.folders == nil { await load() }
        }
        .navigationTitle(base.map { "\(kind.title) · \($0.title)" } ?? kind.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func load() async {
        await model.loadFolders(kind: kind, base: base)
    }
}
