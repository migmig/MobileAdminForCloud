//
//  UserLogDetailForMac.swift
//  MobileAdmin
//
//  macOS 사용자 로그 상세 컬럼 — 툴바에서 인터페이스 흐름 / 실시간 로그 전환
//  두 보기를 모두 살려 두고 보이는 것만 바꿔, 흐름을 보는 동안에도 실시간 스트림이 끊기지 않는다.
//

import SwiftUI

struct UserLogDetailForMac: View {
    @EnvironmentObject private var nav: NavigationState
    @StateObject private var timeline = UserLogTimelineModel()
    @AppStorage(UserLogViewMode.storageKey) private var mode: UserLogViewMode = .timeline

    var body: some View {
        ZStack {
            pane(.timeline) {
                UserLogTimelineView(model: timeline)
            }
            pane(.stream) {
                if let target = nav.userLogTarget {
                    UserLogTailScreen(target: target)
                } else {
                    EmptyStateView(systemImage: "dot.radiowaves.left.and.right",
                                   title: "실시간 로그",
                                   description: "사용자 번호를 입력하고 실시간 보기를 시작하세요.")
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("보기", selection: $mode) {
                    ForEach(UserLogViewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
        .task(id: nav.userLogTimelineRequest) {
            if let request = nav.userLogTimelineRequest {
                timeline.load(request)
            } else {
                timeline.reset()
            }
        }
        .onChange(of: mode) { _, newMode in
            // 숨겨진 흐름 보기의 inspector가 남지 않도록
            if newMode != .timeline {
                timeline.selectedSeq = nil
            }
        }
        .onDisappear {
            timeline.cancel()
        }
    }

    private func pane<Content: View>(_ paneMode: UserLogViewMode, @ViewBuilder content: () -> Content) -> some View {
        let isVisible = mode == paneMode
        return content()
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityHidden(!isVisible)
    }

    private var title: String {
        let number: Int?
        switch mode {
        case .timeline: number = timeline.request?.number.value
        case .stream:   number = nav.userLogTarget?.number.value
        }
        return number.map { "\(SlidebarItem.userLogTail.title) · \($0)" } ?? SlidebarItem.userLogTail.title
    }
}
