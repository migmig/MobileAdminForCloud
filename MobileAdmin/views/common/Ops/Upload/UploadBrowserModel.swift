//
//  UploadBrowserModel.swift
//  MobileAdmin
//
//  업로드 브라우저 상태 — 디렉터리 목록/필터/정렬, 파일 열기(다운로드 → Quick Look)
//

import Foundation

// MARK: - 디렉터리 목록

@MainActor
final class UploadBrowserModel: ObservableObject {
    @Published private(set) var path: UploadPath
    @Published private(set) var response: UploadListResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var filter = ""
    @Published var sort: UploadSort = .server
    @Published var ascending = false

    private let service: UploadService
    private var generation = 0

    init(path: UploadPath = .root, service: UploadService = OpsServices.upload) {
        self.path = path
        self.service = service
    }

    var visibleEntries: [UploadEntry] {
        Self.arrange(response?.entries ?? [], filter: filter, sort: sort, ascending: ascending)
    }

    func load() async {
        generation += 1
        let current = generation
        isLoading = true
        error = nil
        do {
            let result = try await service.list(path)
            guard current == generation else { return }
            response = result
        } catch {
            guard current == generation else { return }
            if !OpsError.isCancellation(error) { self.error = error }
        }
        if current == generation { isLoading = false }
    }

    /// 다른 디렉터리로 이동 (macOS 브레드크럼 / 상위 / 폴더 클릭)
    func go(to newPath: UploadPath) async {
        guard newPath != path else { return }
        path = newPath
        response = nil
        filter = ""
        await load()
    }

    /// 필터 → 정렬. 디렉터리는 항상 먼저 둔다. `.server`는 서버 순서 유지.
    nonisolated static func arrange(_ entries: [UploadEntry],
                                    filter: String,
                                    sort: UploadSort,
                                    ascending: Bool) -> [UploadEntry] {
        let keyword = filter.trimmingCharacters(in: .whitespaces)
        let filtered = keyword.isEmpty ? entries : entries.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
        guard sort != .server else { return filtered }

        func comparison(_ lhs: UploadEntry, _ rhs: UploadEntry) -> ComparisonResult {
            switch sort {
            case .name:
                return lhs.name.localizedStandardCompare(rhs.name)
            case .size:
                return lhs.size == rhs.size ? .orderedSame : (lhs.size < rhs.size ? .orderedAscending : .orderedDescending)
            case .modified:
                return lhs.modTime == rhs.modTime ? .orderedSame : (lhs.modTime < rhs.modTime ? .orderedAscending : .orderedDescending)
            case .server:
                return .orderedSame
            }
        }
        func isOrdered(_ lhs: UploadEntry, _ rhs: UploadEntry) -> Bool {
            let result = comparison(lhs, rhs)
            if result == .orderedSame {
                // 같으면 이름 오름차순으로 고정
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return ascending ? result == .orderedAscending : result == .orderedDescending
        }

        let directories = filtered.filter(\.isDir).sorted(by: isOrdered)
        let files = filtered.filter { !$0.isDir }.sorted(by: isOrdered)
        return directories + files
    }
}

// MARK: - 파일 열기 (다운로드 → Quick Look)

@MainActor
final class UploadFileOpener: ObservableObject {
    /// 이보다 큰 파일은 받기 전에 확인
    static let confirmThreshold: Int64 = 50 * 1024 * 1024

    @Published var previewURL: URL?
    @Published var pendingConfirmation: UploadEntryRef?
    @Published private(set) var loadingRef: UploadEntryRef?
    @Published private(set) var failedRef: UploadEntryRef?
    @Published private(set) var failure: Error?

    private let service: UploadService
    private var task: Task<Void, Never>?

    init(service: UploadService = OpsServices.upload) {
        self.service = service
    }

    /// 큰 파일이고 캐시에 없으면 확인을 먼저 받는다
    func request(_ ref: UploadEntryRef) {
        if ref.entry.size > Self.confirmThreshold && !service.isCached(ref) {
            pendingConfirmation = ref
        } else {
            open(ref)
        }
    }

    func open(_ ref: UploadEntryRef) {
        task?.cancel()
        pendingConfirmation = nil
        failedRef = nil
        failure = nil
        loadingRef = ref
        task = Task {
            do {
                let url = try await service.fetchFile(ref)
                guard loadingRef == ref else { return }
                previewURL = url
            } catch {
                guard loadingRef == ref else { return }
                if !OpsError.isCancellation(error) {
                    failedRef = ref
                    failure = error
                }
            }
            if loadingRef == ref { loadingRef = nil }
        }
    }

    func cancel() {
        task?.cancel()
        loadingRef = nil
    }

    /// 해당 항목의 실패 메시지
    func failureMessage(for ref: UploadEntryRef) -> String? {
        guard failedRef == ref, let failure else { return nil }
        return OpsErrorPresentation(error: failure).summary
    }
}
