import Testing
import Foundation
@testable import MobileAdmin

struct KubectlRunnerTests {

    @Test func run_whenCommandSucceeds_returnsTrimmedStdout() async throws {
        let runner = KubectlRunner(
            processRunner: { executable, arguments in
                #expect(executable == "/usr/local/bin/kubectl")
                #expect(arguments == ["config", "current-context"])
                return KubectlCommandResult(stdout: "dev-context\n", stderr: "", exitCode: 0)
            },
            executableCandidates: ["/usr/local/bin/kubectl"]
        )

        let value = try await runner.run(arguments: ["config", "current-context"])

        #expect(value.stdout == "dev-context")
        #expect(value.exitCode == 0)
    }

    @Test func run_whenNoExecutableCandidate_throwsKubectlNotInstalled() async {
        let runner = KubectlRunner(
            processRunner: { _, _ in
                Issue.record("process runner should not be called")
                return .init(stdout: "", stderr: "", exitCode: 0)
            },
            executableCandidates: []
        )

        do {
            _ = try await runner.run(arguments: ["version", "--client"])
            Issue.record("Expected kubectlNotInstalled")
        } catch let error as KubernetesCommandError {
            #expect(error == .kubectlNotInstalled)
        } catch {
            Issue.record("Expected KubernetesCommandError but got \(error)")
        }
    }

    @Test func run_whenExitCodeNonZero_throwsCommandFailed() async {
        let runner = KubectlRunner(
            processRunner: { _, arguments in
                #expect(arguments == ["get", "pods", "-n", "prod", "-o", "json"])
                return KubectlCommandResult(stdout: "", stderr: "pods is forbidden", exitCode: 1)
            },
            executableCandidates: ["/usr/local/bin/kubectl"]
        )

        do {
            _ = try await runner.run(arguments: ["get", "pods", "-n", "prod", "-o", "json"])
            Issue.record("Expected command failure")
        } catch let error as KubernetesCommandError {
            if case .commandFailed(let stderr, let exitCode, let command) = error {
                #expect(stderr == "pods is forbidden")
                #expect(exitCode == 1)
                #expect(command.contains("kubectl get pods -n prod -o json"))
            } else {
                Issue.record("Expected .commandFailed but got \(error)")
            }
        } catch {
            Issue.record("Expected KubernetesCommandError but got \(error)")
        }
    }

    @Test func run_whenFirstExecutableMissing_triesNextCandidate() async throws {
        let runner = KubectlRunner(
            processRunner: { executable, _ in
                if executable == "/opt/homebrew/bin/kubectl" {
                    throw KubernetesCommandError.kubectlNotInstalled
                }
                return KubectlCommandResult(stdout: "prod-context", stderr: "", exitCode: 0)
            },
            executableCandidates: ["/opt/homebrew/bin/kubectl", "/usr/local/bin/kubectl"]
        )

        let result = try await runner.run(arguments: ["config", "current-context"])

        #expect(result.stdout == "prod-context")
    }
}
