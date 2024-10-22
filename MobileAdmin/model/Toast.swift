
import SwiftUI

struct Toast:Codable ,Hashable{
//    var sn:String?
    var applcBeginDt:String=""
    var applcEndDt:String=""
    var noticeHder:String=""
    var noticeSj:String=""
    var noticeCn:String=""
    var useYn:String = "N"
    
    init(applcBeginDt: String?, applcEndDt: String?, noticeHder: String?, noticeSj: String?, noticeCn: String?, useYn: String?) {
        self.applcBeginDt = applcBeginDt ?? ""
        self.applcEndDt = applcEndDt ?? ""
        self.noticeHder = noticeHder ?? ""
        self.noticeSj = noticeSj ?? ""
        self.noticeCn = noticeCn ?? ""
        self.useYn = useYn ?? ""
    }
    
}
