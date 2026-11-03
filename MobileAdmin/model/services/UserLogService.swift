import Foundation
import Logging

/// 사용자 로그 서비스 (/admin/getUserLog, /admin/getUserLogTail, /admin/getUserLogTimeline)
/// 화면에 원인을 표시해야 하므로 기존 서비스와 달리 오류를 삼키지 않고 throw한다.
struct UserLogService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.UserLogService")

    /// tail 스트림 유휴 타임아웃 — 서버가 heartbeat를 보내지 않으므로 길게 잡는다
    static let tailIdleTimeout: TimeInterval = 3_600

    /// 인터페이스 흐름 — 서버가 로그 파일 전체를 파싱하므로 타임아웃을 길게 잡는다
    static let timelineTimeout: TimeInterval = 120

    typealias TailStream = (fileName: String?, lines: AsyncThrowingStream<String, Error>)

    /// 사용자 로그 파일 전체 다운로드 — macOS는 ~/Downloads, iOS는 앱 Caches에 저장
    func downloadUserLog(_ sno: String, base: NasLogBase? = nil) async throws -> URL {
        guard let number = UserLogNumber(sno) else {
            throw OpsError.invalidUserNumber(sno)
        }
        do {
            let destination = try DownloadStore.downloadURL(category: .userLog, fileName: number.fileName)
            try await client.download(path: "/admin/getUserLog/\(number.value)",
                                      query: [URLQueryItem(name: "base", value: base?.rawValue)],
                                      to: destination)
            logger.info("User log downloaded: \(destination.lastPathComponent)")
            return destination
        } catch {
            logger.error("downloadUserLog 실패: \(error)")
            throw error
        }
    }

    /// 인터페이스 흐름 — 로그에서 ESB/MIDAS 연계, API 진입, WARN/ERROR를 뽑은 하루치 이벤트 (date nil = 최근 날짜)
    func fetchTimeline(number: UserLogNumber, base: NasLogBase?, date: String?) async throws -> UserLogTimeline {
        do {
            return try await client.fetchJSON(path: "/admin/getUserLogTimeline/\(number.value)",
                                              query: [
                                                  URLQueryItem(name: "base", value: base?.rawValue),
                                                  URLQueryItem(name: "date", value: date),
                                              ],
                                              timeout: Self.timelineTimeout)
        } catch {
            if !OpsError.isCancellation(error) {
                logger.error("fetchTimeline 실패: \(error)")
            }
            throw error
        }
    }

    /// 실시간 tail — 최근 N줄 이후 추가되는 줄을 계속 받는다. 스트림 종료(취소) 시 연결도 끊는다.
    func openTail(number: UserLogNumber, lines: Int, base: NasLogBase?) async throws -> TailStream {
        let bytes: URLSession.AsyncBytes
        let response: HTTPURLResponse
        do {
            (bytes, response) = try await client.openStream(
                path: "/admin/getUserLogTail/\(number.value)",
                query: [
                    URLQueryItem(name: "lines", value: String(lines)),
                    URLQueryItem(name: "base", value: base?.rawValue),
                ],
                timeout: Self.tailIdleTimeout
            )
        } catch {
            if !OpsError.isCancellation(error) {
                logger.error("openTail 실패: \(error)")
            }
            throw error
        }

        let fileName = response.value(forHTTPHeaderField: "X-User-Log-File")
        let stream = AsyncThrowingStream<String, Error> { continuation in
            // 바이트 순회는 메인 스레드 밖에서 수행
            let producer = Task.detached(priority: .userInitiated) {
                var splitter = LineSplitter()
                do {
                    for try await byte in bytes {
                        if let line = splitter.append(byte) {
                            continuation.yield(line)
                        }
                    }
                    if let rest = splitter.flush() {
                        continuation.yield(rest)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                producer.cancel()
                bytes.task.cancel()
            }
        }
        return (fileName, stream)
    }
}
