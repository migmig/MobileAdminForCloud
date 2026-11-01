//
//  UserLogTailModel.swift
//  MobileAdmin
//
//  사용자 로그 실시간 tail 상태 모델
//  수신 파이프라인: AsyncBytes ─(백그라운드)→ 줄 분할 → PendingLines ─(150ms 배치, MainActor)→ lines
//

import Foundation

/// 수신 스레드와 MainActor 사이의 줄 버퍼 (lock 보호)
final class PendingLines: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: [String] = []

    func append(_ line: String) {
        lock.lock()
        buffer.append(line)
        lock.unlock()
    }

    func drain() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        let lines = buffer
        buffer.removeAll(keepingCapacity: true)
        return lines
    }
}

/// 스트림/flush Task 보관 (deinit에서 취소하기 위해 lock으로 보호)
final class TaskHandles: @unchecked Sendable {
    private let lock = NSLock()
    private var _stream: Task<Void, Never>?
    private var _flush: Task<Void, Never>?

    var stream: Task<Void, Never>? {
        get { lock.lock(); defer { lock.unlock() }; return _stream }
        set { lock.lock(); _stream = newValue; lock.unlock() }
    }

    var flush: Task<Void, Never>? {
        get { lock.lock(); defer { lock.unlock() }; return _flush }
        set { lock.lock(); _flush = newValue; lock.unlock() }
    }

    func cancelAll() {
        lock.lock()
        let tasks = [_stream, _flush]
        _stream = nil
        _flush = nil
        lock.unlock()
        tasks.forEach { $0?.cancel() }
    }
}

@MainActor
final class UserLogTailModel: ObservableObject {
    enum StopReason: Equatable {
        /// 사용자가 중지 / 화면 이탈
        case user
        /// iOS 백그라운드 전환
        case background
        /// 서버가 스트림을 종료
        case ended
    }

    enum Status: Equatable {
        case idle
        case connecting
        case streaming
        case stopped(StopReason)
        case failed(String)
    }

    typealias Opener = (UserLogTarget) async throws -> UserLogService.TailStream

    @Published private(set) var status: Status = .idle
    @Published private(set) var lines: [LogLine] = []
    @Published private(set) var fileName: String?
    /// 상한 초과로 버린 줄 수
    @Published private(set) var droppedLineCount = 0
    @Published private(set) var lastReceivedAt: Date?
    /// 하단 따라가기
    @Published var follow = true
    @Published private(set) var target: UserLogTarget?

    let maxLines: Int
    private let flushInterval: Duration
    private let opener: Opener
    private let pending = PendingLines()
    /// stop() 없이 모델이 해제돼도 연결이 남지 않도록 deinit에서 취소 (nonisolated 접근용 상자)
    private let tasks = TaskHandles()
    private var streamTask: Task<Void, Never>? {
        get { tasks.stream }
        set { tasks.stream = newValue }
    }
    private var flushTask: Task<Void, Never>? {
        get { tasks.flush }
        set { tasks.flush = newValue }
    }
    private var nextLineID = 0
    /// 세션 번호 — 중지/재시작 후 이전 스트림의 늦은 결과를 무시하기 위함
    private var session = 0

    init(maxLines: Int = 5_000,
         flushInterval: Duration = .milliseconds(150),
         opener: @escaping Opener = { target in
             try await OpsServices.userLog.openTail(number: target.number,
                                                    lines: target.initialLines,
                                                    base: target.base)
         }) {
        self.maxLines = maxLines
        self.flushInterval = flushInterval
        self.opener = opener
    }

    deinit {
        tasks.cancelAll()
    }

    var isActive: Bool {
        status == .connecting || status == .streaming
    }

    // MARK: - 제어

    /// 진행 중인 스트림을 끊고 버퍼를 비운 뒤 새로 시작한다
    func start(_ target: UserLogTarget) {
        cancelTasks()
        session += 1
        let session = self.session
        self.target = target
        lines = []
        droppedLineCount = 0
        nextLineID = 0
        fileName = nil
        lastReceivedAt = nil
        _ = pending.drain()
        follow = true
        status = .connecting

        let opener = self.opener
        let pending = self.pending
        streamTask = Task { [weak self] in
            do {
                let (name, stream) = try await opener(target)
                guard let self, self.session == session else { return }
                self.fileName = name
                self.status = .streaming
                self.startFlushLoop(session: session)

                try await Self.consume(stream, into: pending)

                guard self.session == session else { return }
                self.finish(.stopped(.ended))
            } catch {
                guard let self, self.session == session else { return }
                if OpsError.isCancellation(error) {
                    self.finish(.stopped(.user))
                } else {
                    let message = OpsErrorPresentation(error: error,
                                                       notFoundHint: "사용자 번호와 로그 경로를 확인하세요.").summary
                    self.finish(.failed(message))
                }
            }
        }
    }

    /// 마지막 대상으로 다시 시작 (버퍼 초기화 — 초기 N줄을 다시 받으므로 중복 방지)
    func reconnect() {
        guard let target else { return }
        start(UserLogTarget(number: target.number, base: target.base, initialLines: target.initialLines))
    }

    func stop(reason: StopReason = .user) {
        guard isActive else { return }
        session += 1
        cancelTasks()
        flush()
        status = .stopped(reason)
    }

    /// 화면의 줄만 비운다 (스트림 유지)
    func clear() {
        _ = pending.drain()
        lines = []
        droppedLineCount = 0
    }

    // MARK: - 내부

    /// 스트림을 끝까지 읽어 버퍼에 적재 — MainActor 밖에서 실행된다
    nonisolated private static func consume(_ stream: AsyncThrowingStream<String, Error>,
                                            into pending: PendingLines) async throws {
        for try await line in stream {
            pending.append(line)
        }
    }

    private func finish(_ status: Status) {
        flushTask?.cancel()
        flushTask = nil
        streamTask = nil
        flush()
        self.status = status
    }

    private func cancelTasks() {
        streamTask?.cancel()
        streamTask = nil
        flushTask?.cancel()
        flushTask = nil
    }

    private func startFlushLoop(session: Int) {
        flushTask?.cancel()
        let interval = flushInterval
        flushTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard let self, self.session == session else { return }
                self.flush()
            }
        }
    }

    /// 대기 중인 줄을 화면 목록에 반영하고 상한을 넘는 앞부분을 버린다
    func flush() {
        let incoming = pending.drain()
        guard !incoming.isEmpty else { return }
        lastReceivedAt = Date()

        var updated = lines
        updated.reserveCapacity(min(updated.count + incoming.count, maxLines + incoming.count))
        for text in incoming {
            updated.append(LogLine(id: nextLineID, text: text))
            nextLineID += 1
        }
        let excess = updated.count - maxLines
        if excess > 0 {
            updated.removeFirst(excess)
            droppedLineCount += excess
        }
        lines = updated
    }
}
