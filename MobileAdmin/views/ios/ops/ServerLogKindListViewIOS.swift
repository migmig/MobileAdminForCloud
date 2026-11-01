//
//  ServerLogKindListViewIOS.swift
//  MobileAdmin
//
//  iOS 서버 로그 1단계 — 로그 종류 선택 (+ Backend 경로)
//

import SwiftUI

struct ServerLogKindListViewIOS: View {
    @AppStorage("serverLog.base") private var baseRaw = ServerLogKind.defaultBase.rawValue

    private var base: NasLogBase {
        NasLogBase(rawValue: baseRaw) ?? ServerLogKind.defaultBase
    }

    var body: some View {
        List {
            Section {
                ForEach(ServerLogKind.allCases) { kind in
                    NavigationLink {
                        ServerLogFolderListViewIOS(kind: kind, base: kind.supportsBase ? base : nil)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text(kind.title)
                                    .font(AppFont.listTitle)
                                Text(kind.supportsBase ? "\(kind.summary) · \(base.title)" : kind.summary)
                                    .font(AppFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: kind.systemImage)
                        }
                    }
                }
            } header: {
                Text("로그 종류")
            }

            Section {
                LogBasePicker(title: "Backend 경로",
                              selection: Binding(get: { base }, set: { baseRaw = $0.rawValue }))
            } footer: {
                Text("Backend 로그에만 적용됩니다.")
            }
        }
        .navigationTitle(SlidebarItem.serverLog.title)
    }
}

#Preview {
    NavigationStack {
        ServerLogKindListViewIOS()
    }
}
