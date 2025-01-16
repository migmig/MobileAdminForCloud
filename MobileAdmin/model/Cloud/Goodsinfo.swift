import Foundation

// MARK: - Goodsinfo
struct Goodsinfo :Codable,Identifiable,Hashable{
    let rdt: String?
    let goods: [Good]
    var id:Int?
    let gno: String?
    let kindGb: String?
    let userId: String?
    let registerDt: String?
    init(){
        self.rdt = ""
        self.goods = []
        self.id = 0
        self.gno = ""
        self.kindGb = ""
        self.userId = ""
        self.registerDt = ""
    }
    init(_ userid:String,_ rdt:String){
        self.userId = userid
        self.rdt = rdt
        self.goods = []
        self.id = 0
        self.gno = ""
        self.kindGb = ""
        self.registerDt = ""
    }
    init(_ userid:String,_ rdt:String,_ goods:[Good]){
        self.userId = userid
        self.rdt = rdt
        self.goods = goods
        self.id = 0
        self.gno = ""
        self.kindGb = ""
        self.registerDt = ""
    }
    init(_ userid:String,_ rdt:String,_ gno:String,_ kindGb:String, _ registerDt:String,_ goods:[Good]){
        self.userId = userid
        self.rdt = rdt
        self.goods = goods
        self.id = 0
        self.gno = gno
        self.kindGb = kindGb
        self.registerDt = registerDt
    }
    
    init( id:Int
         ,userid:String
         ,rdt:String
         ,gno:String
         ,kindGb:String
         ,registerDt:String
         ,goods:[Good]){
        self.id     = id
        self.userId = userid
        self.rdt    = rdt
        self.goods  = goods
        self.gno    = gno
        self.kindGb = kindGb
        self.registerDt = registerDt
    }
}

// MARK: - Good
struct Good :Codable,Identifiable,Hashable{
    var id:UUID?=UUID()
    let goodsCd: String
    let maxLmt: Int
    let finProdType:String?
    let goodsNm: String
    let userAlertYn: String?
    var treatmentList: [TreatmentList]?
    let msgDispYn: String?
    let feeRate: Double?
    let inrstMax: Double?
    let autoRptYn: String?
    let goodsContList: [GoodsContList]?
    let userAlertMsg: String?
    let scrinSepratAt: String?
    let bankIemList: [BankIemList]?
    let dispMsg, popDispYn: String?
    let inrstMin: Double?
    init(){
        self.goodsCd = ""
        self.maxLmt = 0
        self.finProdType = ""
        self.goodsNm = ""
        self.userAlertYn = ""
        self.treatmentList = []
        self.msgDispYn = ""
        self.feeRate = 0.0
        self.inrstMax = 0.0
        self.autoRptYn = ""
        self.goodsContList = []
        self.userAlertMsg = ""
        self.scrinSepratAt = ""
        self.bankIemList = []
        self.dispMsg = ""
        self.popDispYn = ""
        self.inrstMin = 0.0
    }
    init(_ goodsCd:String){
        self.goodsNm = ""
        self.goodsCd = goodsCd
        self.maxLmt = 0
        self.finProdType = ""
        self.userAlertYn = ""
        self.treatmentList = []
        self.msgDispYn = ""
        self.feeRate = 0.0
        self.inrstMax = 0.0
        self.autoRptYn = ""
        self.goodsContList = []
        self.userAlertMsg = ""
        self.scrinSepratAt = ""
        self.bankIemList = []
        self.dispMsg = ""
        self.popDispYn = ""
        self.inrstMin = 0.0
    }
    init(_ goodsCd:String, _ goodsNm:String){
        self.goodsNm = goodsNm
        self.goodsCd = goodsCd
        self.maxLmt = 0
        self.finProdType = ""
        self.userAlertYn = ""
        self.treatmentList = []
        self.msgDispYn = ""
        self.feeRate = 0.0
        self.inrstMax = 0.0
        self.autoRptYn = ""
        self.goodsContList = []
        self.userAlertMsg = ""
        self.scrinSepratAt = ""
        self.bankIemList = []
        self.dispMsg = ""
        self.popDispYn = ""
        self.inrstMin = 0.0
    }
    init(_ goodsCd:String, _ goodsNm:String, _ maxLmt:Int){
        self.goodsNm = goodsNm
        self.goodsCd = goodsCd
        self.maxLmt = maxLmt
        self.finProdType = ""
        self.userAlertYn = ""
        self.treatmentList = []
        self.msgDispYn = ""
        self.feeRate = 0.0
        self.inrstMax = 0.0
        self.autoRptYn = ""
        self.goodsContList = []
        self.userAlertMsg = ""
        self.scrinSepratAt = ""
        self.bankIemList = []
        self.dispMsg = ""
        self.popDispYn = ""
        self.inrstMin = 0.0
    }
}

// MARK: - BankIemList
struct BankIemList :Codable,Identifiable,Hashable{
    var id:UUID?=UUID()
    let goodsCd: String?
    let iemCodeNm, iemCode: String?
}


// MARK: - GoodsContList
struct GoodsContList :Codable,Identifiable,Hashable{
    var id:UUID?=UUID()
    let sortNo: String?
    let goodsCd: String?
    let msgUseContent, userMsgTitle: String?
}

// MARK: - TreatmentList
struct TreatmentList :Codable,Identifiable,Hashable{
    var id:UUID?=UUID()
    let sortNo: String?
    let goodsCd: String?
    let treatmentCd: String?
    let useYn: String?
    let treatmentNm: String?
    init(){
        self.sortNo = ""
        self.goodsCd = ""
        self.treatmentCd = ""
        self.useYn = ""
        self.treatmentNm = ""
    }
}
