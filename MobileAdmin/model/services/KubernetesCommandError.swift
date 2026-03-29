import Foundation

enum KubernetesCommandError: LocalizedError, Equatable {
    case kubectlNotInstalled
    case commandFailed(stderr: String, exitCode: Int32, command: String)
    case invalidUTF8Output
    case decodingFailed(command: String, underlying: String)

    var errorDescription: String? {
        switch self {
        case .kubectlNotInstalled:
            return "kubectl 이 설치되어 있지 않거나 앱 환경에서 찾을 수 없습니다"
        case .commandFailed(let stderr, let exitCode, let command):
            return "kubectl 실행 실패 (\(exitCode)): \(command)\n\(stderr)"
        case .invalidUTF8Output:
            return "kubectl 출력이 UTF-8 문자열이 아닙니다"
        case .decodingFailed(let command, let underlying):
            return "kubectl 응답 파싱 실패: \(command)\n\(underlying)"
        }
    }
}
