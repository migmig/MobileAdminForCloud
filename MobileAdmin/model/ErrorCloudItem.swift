
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
}
