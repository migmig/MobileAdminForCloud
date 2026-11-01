//
//  ServerLogSidebar.swift
//  MobileAdmin
//
//  macOS 서버 로그 콘텐츠 컬럼 — 종류/경로/폴더 선택 + 파일 목록
//  (멀티플랫폼 타깃이라 iOS로도 컴파일되므로 macOS 전용 수정자는 #if로 감싼다)
//

import SwiftUI

struct ServerLogSidebar: View {
    @Binding var selection: ServerLogFileRef?

    @AppStorage("serverLog.kind") private var kindRaw = ServerLogKind.backend.rawValue
    @AppStorage("serverLog.base") private var baseRaw = ServerLogKind.defaultBase.rawValue
    /// nil = 루트
    @State private var folder: String?
    @State private var filter = ""
    @StateObject private var model = ServerLogListModel()

    private var kind: ServerLogKind {
        ServerLogKind(rawValue: kindRaw) ?? .backend
    }

    private var base: NasLogBase? {
        kind.supportsBase ? (NasLogBase(rawValue: baseRaw) ?? ServerLogKind.defaultBase) : nil
    }

    private struct SourceKey: Hashable {
        let kind: ServerLogKind
        let base: NasLogBase?
    }

    private struct FilesKey: Hashable {
        let kind: ServerLogKind
        let base: NasLogBase?
        let folder: String?
    }

    var body: some View {
        let files = model.filteredFiles(filter)
        VStack(spacing: 0) {
            controls
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
            Divider()
            List(selection: $selection) {
                if let basePath = model.basePath, NasLogBase.isLocalFallback(basePath) {
                    OpsBanner.nasFallback(basePath: basePath)
                }
                if let error = model.foldersError {
                    OpsBanner.error(error)
                }
                if let error = model.filesError, model.files != nil {
                    OpsBanner.error(error)
                }
                ForEach(files) { file in
                    FileEntryRow(logFile: file)
                        .tag(ServerLogFileRef(kind: kind, base: base, folder: folder, entry: file))
                }
            }
            .overlay {
                if model.files == nil {
                    if let error = model.filesError {
                        OpsErrorView(error: error) {
                            Task { await reloadFiles() }
                        }
                    } else {
                        ProgressView("불러오는 중...")
                    }
                } else if files.isEmpty {
                    EmptyStateView(systemImage: "doc.text.magnifyingglass",
                                   title: filter.isEmpty ? "파일이 없습니다" : "일치하는 파일이 없습니다")
                }
            }
        }
        .searchable(text: $filter, prompt: "파일 이름")
        .navigationTitle(SlidebarItem.serverLog.title)
        #if os(macOS)
        .navigationSubtitle("\(files.count)개")
        #endif
        .toolbar {
            ToolbarItem {
                Button {
                    Task {
                        await model.loadFolders(kind: kind, base: base)
                        await reloadFiles()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("새로고침")
            }
        }
        // 종류/경로가 바뀌면 폴더 목록을 다시 받고 루트로 돌아간다
        .task(id: SourceKey(kind: kind, base: base)) {
            folder = nil
            await model.loadFolders(kind: kind, base: base)
        }
        .task(id: FilesKey(kind: kind, base: base, folder: folder)) {
            await reloadFiles()
        }
        .onChange(of: FilesKey(kind: kind, base: base, folder: folder)) { _, _ in
            selection = nil
            model.clearFiles()
        }
    }

    // MARK: - 상단 컨트롤

    private var controls: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Picker("종류", selection: $kindRaw) {
                ForEach(ServerLogKind.allCases) { kind in
                    Label(kind.title, systemImage: kind.systemImage).tag(kind.rawValue)
                }
            }

            if kind.supportsBase {
                LogBasePicker(title: "경로",
                              selection: Binding(get: { base ?? ServerLogKind.defaultBase },
                                                 set: { baseRaw = $0.rawValue }))
            }

            Picker("폴더", selection: $folder) {
                Text("(루트)").tag(String?.none)
                ForEach(model.folders?.folders ?? []) { folder in
                    Text(folder.name).tag(String?.some(folder.name))
                }
            }
            .disabled(model.isLoadingFolders)
        }
        .pickerStyle(.menu)
        .controlSize(.small)
    }

    private func reloadFiles() async {
        await model.loadFiles(kind: kind, base: base, folder: folder)
    }
}
