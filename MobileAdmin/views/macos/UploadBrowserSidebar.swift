//
//  UploadBrowserSidebar.swift
//  MobileAdmin
//
//  macOS 업로드 브라우저 콘텐츠 컬럼 — 브레드크럼 + 목록 (폴더 클릭 시 이동, 파일 선택 시 상세)
//

import SwiftUI

struct UploadBrowserSidebar: View {
    @Binding var selection: UploadEntryRef?

    @StateObject private var model = UploadBrowserModel()

    var body: some View {
        let entries = model.visibleEntries
        VStack(spacing: 0) {
            breadcrumbBar
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
            Divider()
            List(selection: $selection) {
                if let error = model.error, model.response != nil {
                    OpsBanner.error(error)
                }
                ForEach(entries) { entry in
                    if entry.isDir {
                        Button {
                            Task { await model.go(to: model.path.appending(entry.name)) }
                        } label: {
                            FileEntryRow(upload: entry) {
                                Image(systemName: "chevron.right")
                                    .font(AppFont.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        FileEntryRow(upload: entry)
                            .tag(UploadEntryRef(directory: model.path, entry: entry))
                    }
                }
            }
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
        }
        .searchable(text: $model.filter, prompt: "이름 필터")
        .navigationTitle(SlidebarItem.uploadBrowser.title)
        #if os(macOS)
        .navigationSubtitle("\(entries.count)개")
        #endif
        .toolbar {
            ToolbarItem {
                UploadSortMenu(sort: $model.sort, ascending: $model.ascending)
            }
            ToolbarItem {
                Button {
                    Task { await model.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("새로고침")
            }
        }
        .task {
            if model.response == nil { await model.load() }
        }
        .onChange(of: model.path) { _, _ in
            selection = nil
        }
    }

    // MARK: - 브레드크럼

    private var breadcrumbBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                if let parent = model.path.parent {
                    Task { await model.go(to: parent) }
                }
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(model.path.isRoot)
            .help("상위 폴더")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    Button(SlidebarItem.uploadBrowser.title) {
                        Task { await model.go(to: .root) }
                    }
                    ForEach(model.path.ancestors, id: \.self) { ancestor in
                        Image(systemName: "chevron.right")
                            .font(AppFont.captionSmall)
                            .foregroundStyle(.tertiary)
                        Button(ancestor.lastName ?? "") {
                            Task { await model.go(to: ancestor) }
                        }
                        .fontWeight(ancestor == model.path ? .semibold : .regular)
                    }
                }
            }
        }
        .buttonStyle(.borderless)
        .font(AppFont.caption)
    }
}
