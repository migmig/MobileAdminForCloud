
import Foundation

// MARK: - EdcCrseResponse
struct EdcCrseResponse: Codable {
   let resultCode, resultMsg, resultDescription: String
   let successCount, failCount: Int
   let gcpEdcCrseClAndTimeVO: GcpEdcCrseClAndTimeVO
   init(){
       self.resultCode = ""
       self.resultMsg = ""
       self.resultDescription = ""
       self.successCount = 0
       self.failCount = 0
       self.gcpEdcCrseClAndTimeVO = GcpEdcCrseClAndTimeVO(
           edcCrseID: 0,
           edcCrseName: "",
           edcCrseThumb: "",
           edcStartDt: "",
           edcEndDt: "",
           edcPDMonth: 0,
           edcPDDay: nil,
           lrnRcognTime: 0,
           edcComplExpireMonth: 0,
           lctreIntrcn: "",
           frstRegisterID: "",
           frstRegistDt: nil,
           lastRegisterID: "",
           lastRegistDt: nil,
           gcpEdcCrseTmeList: [],
           atnlcReqYn: "",
           evlScore: 0,
           rmkYn: "",
           rmkCount: 0,
           atnlcLastKey: ""
       )
   }
}

// MARK: - GcpEdcCrseClAndTimeVO
struct GcpEdcCrseClAndTimeVO: Codable,Identifiable {
    var id: Int {
        return self.edcCrseID ?? 0
    }
   let edcCrseID: Int?
   let edcCrseName: String?
   let edcCrseThumb: String?
   let edcStartDt, edcEndDt: String?
   let edcPDMonth: Int?
   let edcPDDay: String?
   let lrnRcognTime, edcComplExpireMonth: Int?
   let lctreIntrcn, frstRegisterID: String?
   let frstRegistDt: Date?
   let lastRegisterID: String?
   let lastRegistDt: Date?
   let gcpEdcCrseTmeList: [GcpEdcCrseTmeList]
   let atnlcReqYn: String?
   let evlScore: Int?
   let rmkYn: String?
   let rmkCount: Int?
   let atnlcLastKey: String?
}

// MARK: - GcpEdcCrseTmeList
struct GcpEdcCrseTmeList: Codable,Hashable,Identifiable {
    var id: Int {
        return self.edcTimeId ?? 0
    }
   let edcTimeId, edcDepthInfo: Int?
   let edcTitleInfo, edcTimeInfo: String?
   let edcVidoUrl: String?
   let edcVidoExtsn, useYn, frstRegisterId: String?
   let frstRegistDt: Date?
   let lastRegisterId: String?
   let lastRegistDt: Date? 
 
}

