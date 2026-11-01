//
//  FileEntryRow.swift
//  MobileAdmin
//
//  파일/폴더 목록 행 — 아이콘, 이름, 크기·수정 시각
//

import SwiftUI

struct FileEntryRow<Trailing: View>: View {
    let name: String
    let kind: FileKind
    /// nil이면 크기를 표시하지 않음 (폴더)
    let size: Int64?
    let modTime: Int64?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: kind.systemImage)
                .foregroundStyle(iconColor)
                .frame(width: AppIconSize.sm)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(name)
                    .font(AppFont.listSubtitle)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.captionSmall)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
            trailing()
        }
        .padding(.vertical, AppSpacing.xxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let size { parts.append(Util.formatFileSize(size)) }
        if let modTime { parts.append(Util.formatUnixTime(modTime)) }
        return parts.joined(separator: " · ")
    }

    private var iconColor: Color {
        switch kind {
        case .folder:  return .accentColor
        case .image:   return .green
        case .pdf:     return .red
        case .text:    return .secondary
        case .video:   return .purple
        case .archive: return .orange
        case .other:   return .secondary
        }
    }
}

extension FileEntryRow where Trailing == EmptyView {
    init(name: String, kind: FileKind, size: Int64?, modTime: Int64?) {
        self.init(name: name, kind: kind, size: size, modTime: modTime) { EmptyView() }
    }

    /// 서버 로그 폴더
    init(folder: LogEntry) {
        self.init(name: folder.name, kind: .folder, size: nil, modTime: folder.modTime)
    }

    /// 서버 로그 파일
    init(logFile: LogEntry) {
        self.init(name: logFile.name, kind: FileKind.from(name: logFile.name, isDirectory: false),
                  size: logFile.size, modTime: logFile.modTime)
    }

    /// 업로드 항목
    init(upload entry: UploadEntry) {
        self.init(name: entry.name, kind: entry.fileKind,
                  size: entry.isDir ? nil : entry.size, modTime: entry.modTime)
    }
}

extension FileEntryRow {
    /// 업로드 항목 + 오른쪽 부가 뷰 (진행 표시 등)
    init(upload entry: UploadEntry, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.init(name: entry.name, kind: entry.fileKind,
                  size: entry.isDir ? nil : entry.size, modTime: entry.modTime, trailing: trailing)
    }
}

#Preview {
    List {
        FileEntryRow(folder: LogEntry(name: "2026-10", size: 4096, modTime: 1_761_955_200))
        FileEntryRow(logFile: LogEntry(name: "app_2026-10-31_0.log.gz", size: 182_734, modTime: 1_761_955_199))
        FileEntryRow(upload: UploadEntry(name: "scan.pdf", isDir: false, size: 2_048_000, modTime: 1_764_899_000))
    }
}
