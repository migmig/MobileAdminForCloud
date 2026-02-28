import SwiftUI
import Logging

/// ViewModel — 더 이상 사용되지 않는 중앙 Facade.
/// 도메인별 ViewModel(ErrorViewModel, BuildViewModel 등)이 각자의 상태와 API를 담당합니다.
/// 남아있는 코드(설정 화면 등)의 하위 호환을 위해 유지합니다.
class ViewModel: ObservableObject {
    let logger = Logger(label: "com.migmig.MobileAdmin.ViewModel")

    static var currentServerType: EnvironmentType = EnvironmentConfig.current

    // 하위 호환: NetworkClient 정적 토큰 위임
    static var token: String? {
        get { NetworkClient.token }
        set { NetworkClient.token = newValue }
    }
    static var tokenExpirationDate: Date? {
        get { NetworkClient.tokenExpirationDate }
        set { NetworkClient.tokenExpirationDate = newValue }
    }

    private let networkClient = NetworkClient()

    func setToken(token: String?) {
        networkClient.setToken(token: token)
    }
}
