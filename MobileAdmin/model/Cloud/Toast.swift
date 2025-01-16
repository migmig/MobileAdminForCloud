
import SwiftUI

struct Toast:Codable ,Hashable{
//    var sn:String?
    var applcBeginDt:Date
    var applcEndDt:Date
    var noticeHder:String=""
    var noticeSj:String=""
    var noticeCn:String=""
    var useYn:String = "N"
    
    init(applcBeginDt: Date?, applcEndDt: Date?, noticeHder: String?, noticeSj: String?, noticeCn: String?, useYn: String?) {
        self.applcBeginDt = applcBeginDt ?? Date()
        self.applcEndDt = applcEndDt ?? Date()
        self.noticeHder = noticeHder ?? ""
        self.noticeSj = noticeSj ?? ""
        self.noticeCn = noticeCn ?? ""
        self.useYn = useYn ?? ""
    }
    
}
