import Foundation

struct EdcCrseClListResponse: Codable {
    let edcCrseClAllList: [EdcCrseCl]?
    let failCount: Int?
    let resultCode: String?
    let successCount: Int?
    let resultDescription, resultMsg: String?
    init(){
        self.edcCrseClAllList = []
        self.failCount = 0
        self.resultCode = ""
        self.successCount = 0
        self.resultDescription = ""
        self.resultMsg = ""
    }
}

struct EdcCrseCl: Identifiable, Codable, Hashable {
    var id : Int?
    let edcStartDt, lctreIntrcn: String?
    let edcCrseThumb: String?
    let frstRegisterID: String?
    let lrnRcognTime, edcCrseID: Int?
    let edcEndDt: String?
    let lastRegisterID: String?
    let evlScore, rmkCount: Int?
    let edcCrseName: String?
    let edcPDMonth: Int?
    let gcpEdcCategoryList: [EdcCategory]?
    let rmkYn: String?
    let edcComplExpireMonth: Int?
    init(){
        self.id = 0
        self.edcStartDt = ""
        self.lctreIntrcn = ""
        self.edcCrseThumb = ""
        self.frstRegisterID = ""
        self.lrnRcognTime = 0
        self.edcCrseID = 0
        self.edcEndDt = ""
        self.lastRegisterID = ""
        self.evlScore = 0
        self.rmkCount = 0
        self.edcCrseName = ""
        self.edcPDMonth = 0
        self.gcpEdcCategoryList = []
        self.rmkYn = ""
        self.edcComplExpireMonth = 0
    }
    init(_ edcCrseName:String, _ lcteIntrcn:String){
        self.id = 0
        self.edcStartDt = ""
        self.lctreIntrcn = lcteIntrcn
        self.edcCrseThumb = ""
        self.frstRegisterID = ""
        self.lrnRcognTime = 0
        self.edcCrseID = 0
        self.edcEndDt = ""
        self.lastRegisterID = ""
        self.evlScore = 0
        self.rmkCount = 0
        self.edcCrseName = edcCrseName
        self.edcPDMonth = 0
        self.gcpEdcCategoryList = []
        self.rmkYn = ""
        self.edcComplExpireMonth = 0
    }
    init(edcStartDt:String
         ,lctreIntrcn:String
         ,edcCrseThumb:String
         ,frstRegisterID:String
         ,lrnRcognTime:Int
         ,edcCrseID:Int
         ,edcEndDt:String
         ,lastRegisterID:String
         ,evlScore:Int
         ,rmkCount:Int
         ,edcCrseName:String
         ,edcPDMonth:Int
         ,gcpEdcCategoryList:[EdcCategory]
         ,rmkYn:String
         ,edcComplExpireMonth:Int){
        self.id = 0
        self.edcStartDt = edcStartDt
        self.lctreIntrcn = lctreIntrcn
        self.edcCrseThumb = edcCrseThumb
        self.frstRegisterID = frstRegisterID
        self.lrnRcognTime = lrnRcognTime
        self.edcCrseID = edcCrseID
        self.edcEndDt = edcEndDt
        self.lastRegisterID = lastRegisterID
        self.evlScore = evlScore
        self.rmkCount = rmkCount
        self.edcCrseName = edcCrseName
        self.edcPDMonth = edcPDMonth
        self.gcpEdcCategoryList = gcpEdcCategoryList
        self.rmkYn = rmkYn
        self.edcComplExpireMonth = edcComplExpireMonth
    }
}

struct EdcCategory : Codable, Hashable {
    let sortNo: Int?
    let lastRegisterID, frstRegisterID: String?
    let categoryCode: String?
    let useAt: String?
    let categoryName: String?
    let categoryID: Int?
}


