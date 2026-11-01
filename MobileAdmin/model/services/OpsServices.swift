import Foundation

/// 운영 기능(사용자 로그 / 서버 로그 / 업로드) 서비스 공유 인스턴스
/// 화면 단위 상태 모델이 기본값으로 사용하고, 테스트에서는 직접 주입한다.
/// 토큰은 NetworkClient의 static 상태라 ViewModel의 클라이언트와 인증을 공유한다.
enum OpsServices {
    static let client = NetworkClient()
    static let userLog = UserLogService(client: client)
    static let serverLog = ServerLogService(client: client)
    static let upload = UploadService(client: client)
}
