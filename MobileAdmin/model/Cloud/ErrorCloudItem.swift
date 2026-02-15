
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
    var severity: SeverityLevel?
    var occurrenceCount: Int?

    init(code: String? = nil,
         description: String? = nil,
         id: Int? = nil,
         msg: String? = nil,
         registerDt: String? = nil,
         requestInfo: String? = nil,
         restUrl: String? = nil,
         traceCn: String? = nil,
         userId: String? = nil,
         severity: SeverityLevel? = nil,
         occurrenceCount: Int? = nil) {
        self.code = code
        self.description = description
        self.id = id
        self.msg = msg
        self.registerDt = registerDt
        self.requestInfo = requestInfo
        self.restUrl = restUrl
        self.traceCn = traceCn
        self.userId = userId
        self.severity = severity
        self.occurrenceCount = occurrenceCount
    }

    init(){
        self.code = ""
        self.description = ""
        self.id = 0
        self.msg = ""
        self.registerDt = ""
        self.requestInfo = ""
        self.restUrl = ""
        self.traceCn = ""
        self.userId = ""
        self.severity = .medium
        self.occurrenceCount = 1
    }

    /// 심각도가 없으면 메시지/코드로부터 자동 추론
    mutating func ensureSeverity() {
        if severity == nil {
            severity = SeverityLevel.derived(from: self)
        }
    }
}
