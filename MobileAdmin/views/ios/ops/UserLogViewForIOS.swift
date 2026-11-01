//
//  UserLogViewForIOS.swift
//  MobileAdmin
//
//  iOS 사용자 로그 — 입력 폼(시작 시 접힘) + 상태 바 + 실시간 로그
//

import SwiftUI

struct UserLogViewForIOS: View {
    @StateObject private var model = UserLogTailModel()
    @StateObject private var download = FileDownloadModel()
    @State private var numberText: String
    @State private var isFormExpanded = true
    @AppStorage("userLog.base") private var baseRaw = ""
    @AppStorage("userLog.lines") private var initialLines = UserLogTarget.defaultLines
    @Environment(\.scenePhase) private var scenePhase

    /// 오류 상세 등에서 번호를 넘겨 진입하면 바로 시작
    private let autoStartNumber: UserLogNumber?

    init(initialNumber: String? = nil) {
        _numberText = State(initialValue: initialNumber ?? "")
        autoStartNumber = initialNumber.flatMap { UserLogNumber($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: $isFormExpanded) {
                UserLogForm(numberText: $numberText,
                            base: $baseRaw.nasLogBase,
                            initialLines: $initialLines,
                            isStreaming: model.isActive,
                            isDownloading: download.isDownloading,
                            onStart: start,
                            onDownload: downloadAll)
                    .padding(.top, AppSpacing.sm)
            } label: {
                Label(formTitle, systemImage: "person.text.rectangle")
                    .font(AppFont.listTitle)
            }
            .padding(AppSpacing.md)

            if download.hasStatus {
                DownloadStatusView(model: download)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
            }

            Divider()
            UserLogTailView(model: model)
        }
        .navigationTitle(SlidebarItem.userLogTail.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            if let number = autoStartNumber, model.status == .idle {
                start(UserLogTarget(number: number, base: NasLogBase(rawValue: baseRaw), initialLines: initialLines))
            }
        }
        .onDisappear {
            model.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                model.stop(reason: .background)
            case .active:
                if model.status == .stopped(.background) {
                    model.reconnect()
                }
            default:
                break
            }
        }
    }

    private var formTitle: String {
        if let target = model.target, !isFormExpanded {
            return "사용자 \(target.number.value)"
        }
        return "조회 조건"
    }

    private func start(_ target: UserLogTarget) {
        model.start(target)
        withAnimation { isFormExpanded = false }
    }

    private func downloadAll(_ number: UserLogNumber, _ base: NasLogBase?) {
        download.start {
            try await OpsServices.userLog.downloadUserLog(String(number.value), base: base)
        }
    }
}

#Preview {
    NavigationStack {
        UserLogViewForIOS()
    }
}
