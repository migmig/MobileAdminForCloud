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
    var id : Int?{
        return self.edcCrseId
    }
    let edcStartDt, lctreIntrcn: String?
    let edcCrseThumb: String?
    let frstRegisterId: String?
    let lrnRcognTime, edcCrseId: Int?
    let edcEndDt: String?
    let lastRegisterId: String?
    let evlScore, rmkCount: Int?
    let edcCrseName: String?
    let edcPDMonth: Int?
    let gcpEdcCategoryList: [EdcCategory]?
    let rmkYn: String?
    let edcComplExpireMonth: Int?
    init(){
        self.edcStartDt = ""
        self.lctreIntrcn = ""
        self.edcCrseThumb = ""
        self.frstRegisterId = ""
        self.lrnRcognTime = 0
        self.edcCrseId = 0
        self.edcEndDt = ""
        self.lastRegisterId = ""
        self.evlScore = 0
        self.rmkCount = 0
        self.edcCrseName = ""
        self.edcPDMonth = 0
        self.gcpEdcCategoryList = []
        self.rmkYn = ""
        self.edcComplExpireMonth = 0
    }
    init(edcCrseId:Int,edcCrseName:String,lcteIntrcn:String){
        self.edcStartDt = ""
        self.lctreIntrcn = lcteIntrcn
        self.edcCrseThumb = ""
        self.frstRegisterId = ""
        self.lrnRcognTime = 0
        self.edcCrseId = edcCrseId
        self.edcEndDt = ""
        self.lastRegisterId = ""
        self.evlScore = 0
        self.rmkCount = 0
        self.edcCrseName = edcCrseName
        self.edcPDMonth = 0
        self.gcpEdcCategoryList = []
        self.rmkYn = ""
        self.edcComplExpireMonth = 0
    }
    init(_ edcCrseName:String, _ lcteIntrcn:String){
        self.edcStartDt = ""
        self.lctreIntrcn = lcteIntrcn
        self.edcCrseThumb = ""
        self.frstRegisterId = ""
        self.lrnRcognTime = 0
        self.edcCrseId = 0
        self.edcEndDt = ""
        self.lastRegisterId = ""
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
         ,frstRegisterId:String
         ,lrnRcognTime:Int
         ,edcCrseId:Int
         ,edcEndDt:String
         ,lastRegisterId:String
         ,evlScore:Int
         ,rmkCount:Int
         ,edcCrseName:String
         ,edcPDMonth:Int
         ,gcpEdcCategoryList:[EdcCategory]
         ,rmkYn:String
         ,edcComplExpireMonth:Int){ 
        self.edcStartDt = edcStartDt
        self.lctreIntrcn = lctreIntrcn
        self.edcCrseThumb = edcCrseThumb
        self.frstRegisterId = frstRegisterId
        self.lrnRcognTime = lrnRcognTime
        self.edcCrseId = edcCrseId
        self.edcEndDt = edcEndDt
        self.lastRegisterId = lastRegisterId
        self.evlScore = evlScore
        self.rmkCount = rmkCount
        self.edcCrseName = edcCrseName
        self.edcPDMonth = edcPDMonth
        self.gcpEdcCategoryList = gcpEdcCategoryList
        self.rmkYn = rmkYn
        self.edcComplExpireMonth = edcComplExpireMonth
    }
}

struct EdcCategory : Codable, Hashable,Identifiable {
    var id: Int{
        return self.categoryId ?? 0
    }
    let sortNo: Int?
    let lastRegisterId, frstRegisterId: String?
    let categoryCode: String?
    let useAt: String?
    let categoryName: String?
    let categoryId: Int?
}
 

