//
//  LineSplitterTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
@testable import MobileAdmin

struct LineSplitterTests {

    /// 바이트를 하나씩 넣고 완성된 줄 + flush 결과를 모은다
    private func split(_ bytes: [UInt8], maxLineBytes: Int = LineSplitter.maxLineBytes) -> [String] {
        var splitter = LineSplitter(maxLineBytes: maxLineBytes)
        var lines: [String] = []
        for byte in bytes {
            if let line = splitter.append(byte) { lines.append(line) }
        }
        if let rest = splitter.flush() { lines.append(rest) }
        return lines
    }

    @Test func splitsOnNewline() {
        #expect(split(Array("a\nb\n".utf8)) == ["a", "b"])
    }

    @Test func handlesCRLF() {
        #expect(split(Array("a\r\nb\r\n".utf8)) == ["a", "b"])
    }

    @Test func preservesEmptyLines() {
        #expect(split(Array("a\n\n\nb\n".utf8)) == ["a", "", "", "b"])
    }

    @Test func flushesPartialLastLine() {
        #expect(split(Array("a\nbc".utf8)) == ["a", "bc"])
    }

    @Test func noFlushWhenEndsWithNewline() {
        var splitter = LineSplitter()
        for byte in Array("a\n".utf8) { _ = splitter.append(byte) }
        #expect(splitter.flush() == nil)
    }

    /// 청크 경계에서 멀티바이트 문자가 쪼개져도 줄이 완성된 뒤 디코딩하므로 깨지지 않는다
    @Test func multibyteCharactersAcrossChunks() {
        let bytes = Array("한글 로그 ✅\n두번째\n".utf8)
        var splitter = LineSplitter()
        var lines: [String] = []
        // 3바이트 한글을 일부러 2바이트 단위 청크로 나눠 넣는다
        stride(from: 0, to: bytes.count, by: 2).forEach { start in
            for byte in bytes[start..<min(start + 2, bytes.count)] {
                if let line = splitter.append(byte) { lines.append(line) }
            }
        }
        #expect(lines == ["한글 로그 ✅", "두번째"])
    }

    @Test func forcesSplitOverMaxLength() {
        #expect(split(Array("abcdef\n".utf8), maxLineBytes: 4) == ["abcd", "ef"])
    }
}
