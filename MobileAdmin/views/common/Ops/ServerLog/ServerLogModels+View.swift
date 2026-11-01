//
//  ServerLogModels+View.swift
//  MobileAdmin
//
//  서버 로그 화면 상태 모델 — 폴더/파일 목록, 파일 내용
//

import Foundation

// MARK: - 폴더 / 파일 목록

@MainActor
final class ServerLogListModel: ObservableObject {
    @Published private(set) var folders: LogFolderListResponse?
    @Published private(set) var files: LogFileListResponse?
    @Published private(set) var isLoadingFolders = false
    @Published private(set) var isLoadingFiles = false
    @Published private(set) var foldersError: Error?
    @Published private(set) var filesError: Error?

    private let service: ServerLogService
    private var folderGeneration = 0
    private var fileGeneration = 0

    init(service: ServerLogService = OpsServices.serverLog) {
        self.service = service
    }

    /// 서버가 실제로 보고 있는 base 경로 (NAS 폴백 경고용)
    var basePath: String? { files?.base ?? folders?.base }

    func loadFolders(kind: ServerLogKind, base: NasLogBase?) async {
        folderGeneration += 1
        let current = folderGeneration
        isLoadingFolders = true
        foldersError = nil
        do {
            let result = try await service.fetchFolders(kind: kind, base: base)
            guard current == folderGeneration else { return }
            folders = result
        } catch {
            guard current == folderGeneration else { return }
            if !OpsError.isCancellation(error) { foldersError = error }
        }
        if current == folderGeneration { isLoadingFolders = false }
    }

    func loadFiles(kind: ServerLogKind, base: NasLogBase?, folder: String?) async {
        fileGeneration += 1
        let current = fileGeneration
        isLoadingFiles = true
        filesError = nil
        do {
            let result = try await service.fetchFiles(kind: kind, base: base, folder: folder)
            guard current == fileGeneration else { return }
            files = result
        } catch {
            guard current == fileGeneration else { return }
            if !OpsError.isCancellation(error) { filesError = error }
        }
        if current == fileGeneration { isLoadingFiles = false }
    }

    /// 다른 폴더로 바뀔 때 이전 파일 목록 제거 (잘못된 참조 선택 방지)
    func clearFiles() {
        files = nil
        filesError = nil
    }

    func filteredFiles(_ filter: String) -> [LogEntry] {
        let all = files?.files ?? []
        let trimmed = filter.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}

// MARK: - 파일 내용

@MainActor
final class ServerLogContentModel: ObservableObject {
    @Published private(set) var content: LogContent?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let service: ServerLogService
    private var generation = 0

    init(service: ServerLogService = OpsServices.serverLog) {
        self.service = service
    }

    /// 다시 읽는 동안에도 이전 내용을 유지한다 (깜빡임 방지)
    func load(_ ref: ServerLogFileRef, tail: Int) async {
        generation += 1
        let current = generation
        isLoading = true
        error = nil
        do {
            let result = try await service.fetchContent(ref, tail: tail)
            guard current == generation else { return }
            content = result
        } catch {
            guard current == generation else { return }
            if !OpsError.isCancellation(error) { self.error = error }
        }
        if current == generation { isLoading = false }
    }
}
