//
//  LineSplitter.swift
//  MobileAdmin
//
//  바이트 스트림 → 줄 단위 분할기
//  - 청크가 줄 경계와 무관하게 와도 '\n' 기준으로 조립한다
//  - 줄이 완성된 뒤 UTF-8로 디코딩하므로 멀티바이트 문자가 쪼개져 와도 깨지지 않는다
//  - URLSession.AsyncBytes.lines 대신 사용: 빈 줄 보존, 최대 줄 길이 제어
//

import Foundation

struct LineSplitter {
    /// 서버(bufio.Scanner)와 동일한 1MiB 제한 — 넘으면 강제로 끊어서 내보낸다
    static let maxLineBytes = 1 << 20

    private var buffer: [UInt8] = []
    private let maxLineBytes: Int

    init(maxLineBytes: Int = LineSplitter.maxLineBytes) {
        self.maxLineBytes = maxLineBytes
        buffer.reserveCapacity(512)
    }

    /// 바이트 하나를 추가하고, 줄이 완성되면 반환한다
    mutating func append(_ byte: UInt8) -> String? {
        if byte == 0x0A {
            return emit()
        }
        buffer.append(byte)
        if buffer.count >= maxLineBytes {
            return emit()
        }
        return nil
    }

    /// 스트림 종료 시 남은 부분 줄 반환
    mutating func flush() -> String? {
        buffer.isEmpty ? nil : emit()
    }

    private mutating func emit() -> String {
        if buffer.last == 0x0D {
            buffer.removeLast()
        }
        let line = String(decoding: buffer, as: UTF8.self)
        buffer.removeAll(keepingCapacity: true)
        return line
    }
}
