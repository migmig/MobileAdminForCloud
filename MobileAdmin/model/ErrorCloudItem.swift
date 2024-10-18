
import SwiftUI

struct ErrorCloudItem:Codable,Identifiable,Hashable{
    var code: String?
    var description: String?
    var id: Int?
    var msg: String?
    var registerDt: String?
    var requestInfo: String?
    var restUrl: String?
    var traceCn: String?
    var userId: String?
    init(code: String? = nil, description: String? = nil, id: Int? = nil, msg: String? = nil, registerDt: String? = nil, requestInfo: String? = nil, restUrl: String? = nil, traceCn: String? = nil, userId: String? = nil) {
        self.code = code
        self.description = description
        self.id = id
        self.msg = msg
        self.registerDt = registerDt
        self.requestInfo = requestInfo
        self.restUrl = restUrl
        self.traceCn = traceCn
        self.userId = userId
    }
}
