//
//  UserLogForm.swift
//  MobileAdmin
//
//  사용자 로그 조회 입력 폼 — 번호, 로그 경로, 초기 줄 수, 흐름 분석/실시간 시작/전체 다운로드
//

import SwiftUI

struct UserLogForm: View {
    @Binding var numberText: String
    @Binding var base: NasLogBase?
    @Binding var initialLines: Int
    var isStreaming: Bool
    var isDownloading: Bool
    var onStart: (UserLogTarget) -> Void
    var onAnalyze: (UserLogNumber, NasLogBase?) -> Void
    var onDownload: (UserLogNumber, NasLogBase?) -> Void

    private var number: UserLogNumber? {
        UserLogNumber(numberText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            TextField("사용자 번호 (예: 109114)", text: $numberText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                #if os(iOS)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit(start)

            Text(hintText)
                .font(AppFont.captionSmall)
                .foregroundStyle(number == nil && !numberText.isEmpty ? Color.red : Color.secondary)

            HStack(spacing: AppSpacing.md) {
                LogBasePicker(selection: $base, allowsAuto: true)
                    .fixedSize()
                Picker("초기 줄 수", selection: $initialLines) {
                    ForEach(UserLogTarget.lineOptions, id: \.self) { option in
                        Text("\(option)줄").tag(option)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }

            HStack(spacing: AppSpacing.sm) {
                Button {
                    if let number { onAnalyze(number, base) }
                } label: {
                    Label("흐름 분석", systemImage: "point.3.connected.trianglepath.dotted")
                }
                .buttonStyle(.borderedProminent)
                .disabled(number == nil)

                Button(action: start) {
                    Label(isStreaming ? "실시간 다시 시작" : "실시간 보기", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
                .disabled(number == nil)

                Button {
                    if let number { onDownload(number, base) }
                } label: {
                    Label("전체 다운로드", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .disabled(number == nil || isDownloading)
            }
            .controlSize(.small)
        }
    }

    private var hintText: String {
        if let number { return "대상 파일: \(number.fileName)" }
        return numberText.isEmpty ? "사용자 번호를 입력하세요 (UT 접두사 가능)" : "숫자로 된 사용자 번호를 입력하세요"
    }

    private func start() {
        guard let number else { return }
        onStart(UserLogTarget(number: number, base: base, initialLines: initialLines))
    }
}
