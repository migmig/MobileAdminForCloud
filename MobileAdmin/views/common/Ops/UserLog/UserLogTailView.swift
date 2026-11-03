//
//  UserLogTailView.swift
//  MobileAdmin
//
//  사용자 로그 실시간 뷰 — 상태 바 + 로그 뷰어 (중지/재연결/지우기/공유)
//

import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

struct UserLogTailView: View {
    @ObservedObject var model: UserLogTailModel

    var body: some View {
        VStack(spacing: 0) {
            UserLogStatusBar(model: model)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
            Divider()
            LogViewerPanel(lines: model.lines,
                           follow: $model.follow,
                           emptyTitle: emptyTitle,
                           emptyDescription: emptyDescription) {
                if model.isActive {
                    Button {
                        model.stop()
                    } label: {
                        Label("중지", systemImage: "stop.fill")
                    }
                } else if model.target != nil {
                    Button {
                        model.reconnect()
                    } label: {
                        Label("재연결", systemImage: "arrow.clockwise")
                    }
                }

                Button {
                    model.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(model.lines.isEmpty)
                .help("화면 지우기")
                .accessibilityLabel("화면 지우기")

                ShareLink(item: LogSnapshot(fileName: snapshotFileName, lines: model.lines),
                          preview: SharePreview(snapshotFileName)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(model.lines.isEmpty)
                .help("현재 화면 로그 공유")
                .accessibilityLabel("현재 화면 로그 공유")
            }
        }
    }

    private var emptyTitle: String {
        switch model.status {
        case .connecting: return "연결 중..."
        case .streaming:  return "새 로그를 기다리는 중"
        default:          return "표시할 로그가 없습니다"
        }
    }

    private var emptyDescription: String? {
        model.target == nil ? "사용자 번호를 입력하고 시작하세요." : nil
    }

    private var snapshotFileName: String {
        let name = model.fileName ?? model.target?.number.fileName ?? "user-log.log"
        return (name as NSString).deletingPathExtension + "_snapshot.log"
    }
}

// MARK: - 상태 바

struct UserLogStatusBar: View {
    @ObservedObject var model: UserLogTailModel

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            statusIndicator
            Text(statusText)
                .font(AppFont.caption)
                .lineLimit(2)

            if let name = model.fileName ?? model.target?.number.fileName {
                Text(name)
                    .font(AppFont.mono)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.sm)

            if model.droppedLineCount > 0 {
                OpsTag(text: "앞부분 \(model.droppedLineCount)줄 생략", tint: .orange)
            }

            if let last = model.lastReceivedAt {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text("마지막 수신 \(Self.relative(from: last, to: context.date))")
                        .font(AppFont.captionSmall)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch model.status {
        case .connecting:
            ProgressView().controlSize(.small)
        default:
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
    }

    private var statusColor: Color {
        switch model.status {
        case .idle:       return .secondary
        case .connecting: return .yellow
        case .streaming:  return .green
        case .stopped:    return .gray
        case .failed:     return .red
        }
    }

    private var statusText: String {
        switch model.status {
        case .idle:                  return "대기"
        case .connecting:            return "연결 중..."
        case .streaming:             return "수신 중"
        case .stopped(.user):        return "중지됨"
        case .stopped(.background):  return "백그라운드 전환으로 중지됨"
        case .stopped(.ended):       return "서버가 연결을 종료했습니다"
        case .failed(let message):   return message
        }
    }

    static func relative(from date: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 { return "\(seconds)초 전" }
        if seconds < 3_600 { return "\(seconds / 60)분 전" }
        return "\(seconds / 3_600)시간 전"
    }
}

// MARK: - 공유용 스냅샷 (공유 시점에 파일 생성)

struct LogSnapshot: Transferable {
    let fileName: String
    let lines: [LogLine]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { snapshot in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(snapshot.fileName)
            try snapshot.lines.map(\.text).joined(separator: "\n")
                .write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}

// MARK: - macOS 상세 컬럼용 (대상이 바뀌면 재시작, 화면 이탈 시 중지, 제목은 UserLogDetailForMac이 정한다)

struct UserLogTailScreen: View {
    let target: UserLogTarget

    @StateObject private var model = UserLogTailModel()

    var body: some View {
        UserLogTailView(model: model)
            .task(id: target) {
                model.start(target)
            }
            .onDisappear {
                model.stop()
            }
    }
}
