//
//  LogText.swift
//  MobileAdmin
//
//  로그 텍스트 표시용 모델
//

import Foundation

/// 로그 한 줄 — id는 단조 증가 (ScrollViewReader 앵커로 사용)
struct LogLine: Identifiable, Hashable {
    let id: Int
    let text: String
}

/// 서버 로그 content 응답 (마지막 N줄)
struct LogContent {
    let fileName: String
    /// 잘림 표식 줄은 제외된 본문
    let lines: [LogLine]
    let tailLines: Int
    let truncated: Bool

    /// 서버가 잘린 경우 본문 첫 줄에 넣는 표식: "... (앞부분 생략, 최근 {N}줄만 표시) ..."
    static let truncationMarkerPrefix = "... (앞부분 생략"

    /// content 응답 본문 파싱 — 마지막 개행 처리, CR 제거, 잘림 표식 줄 제거
    static func parse(_ data: Data, fileName: String, headerTailLines: Int?, truncated: Bool) -> LogContent {
        let text = String(decoding: data, as: UTF8.self)
        // Swift에서 "\r\n"은 하나의 Character라 "\n"만으로는 나눠지지 않는다
        var parts = text.split(omittingEmptySubsequences: false,
                               whereSeparator: { $0 == "\n" || $0 == "\r\n" })
        if parts.last?.isEmpty == true {
            parts.removeLast()
        }
        if truncated, let first = parts.first, first.hasPrefix(truncationMarkerPrefix) {
            parts.removeFirst()
        }
        let lines = parts.enumerated().map { index, part in
            LogLine(id: index, text: part.hasSuffix("\r") ? String(part.dropLast()) : String(part))
        }
        return LogContent(fileName: fileName,
                          lines: lines,
                          tailLines: headerTailLines ?? lines.count,
                          truncated: truncated)
    }
}
