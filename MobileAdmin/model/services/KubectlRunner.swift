import Foundation

struct KubectlCommandResult: Equatable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

protocol KubectlRunning {
    func run(arguments: [String]) async throws -> KubectlCommandResult
}

struct KubectlRunner: KubectlRunning {
    typealias ProcessRunner = (_ executable: String, _ arguments: [String]) async throws -> KubectlCommandResult

    private let processRunner: ProcessRunner
    private let executableCandidates: [String]

    init(
        processRunner: @escaping ProcessRunner = KubectlRunner.runProcess,
        executableCandidates: [String] = ["/opt/homebrew/bin/kubectl", "/usr/local/bin/kubectl", "/usr/bin/kubectl"]
    ) {
        self.processRunner = processRunner
        self.executableCandidates = executableCandidates
    }

    func run(arguments: [String]) async throws -> KubectlCommandResult {
        guard !executableCandidates.isEmpty else {
            throw KubernetesCommandError.kubectlNotInstalled
        }

        var lastInstallError: KubernetesCommandError?

        for executable in executableCandidates {
            do {
                let result = try await processRunner(executable, arguments)
                if result.exitCode != 0 {
                    let command = (["kubectl"] + arguments).joined(separator: " ")
                    throw KubernetesCommandError.commandFailed(
                        stderr: result.stderr.trimmingCharacters(in: .whitespacesAndNewlines),
                        exitCode: result.exitCode,
                        command: command
                    )
                }

                return KubectlCommandResult(
                    stdout: result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                    stderr: result.stderr.trimmingCharacters(in: .whitespacesAndNewlines),
                    exitCode: result.exitCode
                )
            } catch let error as KubernetesCommandError {
                if case .kubectlNotInstalled = error {
                    lastInstallError = error
                    continue
                }
                throw error
            }
        }

        throw lastInstallError ?? .kubectlNotInstalled
    }

    private static func runProcess(executable: String, arguments: [String]) async throws -> KubectlCommandResult {
        #if os(macOS)
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { process in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                guard let stdout = String(data: stdoutData, encoding: .utf8),
                      let stderr = String(data: stderrData, encoding: .utf8) else {
                    continuation.resume(throwing: KubernetesCommandError.invalidUTF8Output)
                    return
                }

                continuation.resume(returning: KubectlCommandResult(
                    stdout: stdout,
                    stderr: stderr,
                    exitCode: process.terminationStatus
                ))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: KubernetesCommandError.kubectlNotInstalled)
            }
        }
        #else
        throw KubernetesCommandError.kubectlNotInstalled
        #endif
    }
}
