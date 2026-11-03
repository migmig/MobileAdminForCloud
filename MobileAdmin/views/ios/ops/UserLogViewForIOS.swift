//
//  UserLogViewForIOS.swift
//  MobileAdmin
//
//  iOS 사용자 로그 — 입력 폼(시작 시 접힘) + 보기 전환(인터페이스 흐름 | 실시간 로그)
//  두 모델을 모두 들고 있어 보기를 바꿔도 실시간 스트림과 흐름 결과가 유지된다.
//

import SwiftUI

struct UserLogViewForIOS: View {
    @StateObject private var model = UserLogTailModel()
    @StateObject private var timeline = UserLogTimelineModel()
    @StateObject private var download = FileDownloadModel()
    @State private var numberText: String
    @State private var isFormExpanded = true
    /// 이벤트 상세로 push하면서 스트림을 멈췄는지 — 돌아오면 다시 연결
    @State private var pausedForPush = false
    @AppStorage("userLog.base") private var baseRaw = ""
    @AppStorage("userLog.lines") private var initialLines = UserLogTarget.defaultLines
    @AppStorage(UserLogViewMode.storageKey) private var mode: UserLogViewMode = .timeline
    @Environment(\.scenePhase) private var scenePhase

    /// 오류 상세 등에서 번호를 넘겨 진입하면 바로 시작
    private let autoStartNumber: UserLogNumber?
    /// 자동 시작할 보기 (nil = 실시간)
    private let autoStartMode: UserLogViewMode
    /// 흐름 분석 자동 시작 시 날짜 (nil = 최근)
    private let autoStartDate: String?

    init(initialNumber: String? = nil, initialMode: UserLogViewMode = .stream, initialDate: String? = nil) {
        _numberText = State(initialValue: initialNumber ?? "")
        autoStartNumber = initialNumber.flatMap { UserLogNumber($0) }
        autoStartMode = initialMode
        autoStartDate = initialDate
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
                            onAnalyze: { number, base in
                                analyze(UserLogTimelineRequest(number: number, base: base))
                            },
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

            Picker("보기", selection: $mode) {
                ForEach(UserLogViewMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

            Divider()
            switch mode {
            case .timeline:
                UserLogTimelineView(model: timeline)
            case .stream:
                UserLogTailView(model: model)
            }
        }
        .navigationTitle(SlidebarItem.userLogTail.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            guard let number = autoStartNumber, model.status == .idle, timeline.phase == .idle else { return }
            let base = NasLogBase(rawValue: baseRaw)
            switch autoStartMode {
            case .timeline:
                analyze(UserLogTimelineRequest(number: number, base: base, date: autoStartDate))
            case .stream:
                start(UserLogTarget(number: number, base: base, initialLines: initialLines))
            }
        }
        .onAppear {
            if pausedForPush {
                pausedForPush = false
                model.reconnect()
            }
        }
        .onDisappear {
            // 뒤로 가기뿐 아니라 이벤트 상세 push에서도 호출된다. 화면 밖 연결은 끊고, 돌아오면 다시 연결한다.
            if model.isActive {
                model.stop()
                pausedForPush = true
            }
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
        guard !isFormExpanded else { return "조회 조건" }
        let number: Int?
        switch mode {
        case .timeline: number = timeline.request?.number.value
        case .stream:   number = model.target?.number.value
        }
        return number.map { "사용자 \($0)" } ?? "조회 조건"
    }

    private func start(_ target: UserLogTarget) {
        model.start(target)
        mode = .stream
        withAnimation { isFormExpanded = false }
    }

    private func analyze(_ request: UserLogTimelineRequest) {
        timeline.load(request)
        mode = .timeline
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
