//
//  UserLogTarget.swift
//  MobileAdmin
//
//  사용자 로그 조회 대상 모델 (/admin/getUserLog, /admin/getUserLogTail)
//

import Foundation

/// 사용자 번호 — 입력 정규화: 공백 제거 → "UT" 접두사 제거 → 숫자만 → 양의 정수
struct UserLogNumber: Hashable {
    let value: Int

    init?(_ raw: String) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.uppercased().hasPrefix("UT") {
            text = String(text.dropFirst(2))
        }
        guard !text.isEmpty,
              text.allSatisfy({ $0.isASCII && $0.isNumber }),
              let value = Int(text),
              value > 0 else {
            return nil
        }
        self.value = value
    }

    /// 서버 파일명 규칙: UT + 11자리 0 패딩
    var fileName: String {
        String(format: "UT%011d.log", value)
    }
}

/// 실시간 tail 대상
struct UserLogTarget: Hashable {
    /// 초기 줄 수 선택지 (서버 최대 1000)
    static let lineOptions = [100, 200, 500, 1000]
    static let defaultLines = 200

    let number: UserLogNumber
    /// nil = 자동 (서버 기본 경로)
    let base: NasLogBase?
    let initialLines: Int
    /// 같은 대상을 다시 시작해도 값이 달라지도록
    let requestedAt: Date

    init(number: UserLogNumber, base: NasLogBase?, initialLines: Int, requestedAt: Date = Date()) {
        self.number = number
        self.base = base
        self.initialLines = initialLines
        self.requestedAt = requestedAt
    }
}
