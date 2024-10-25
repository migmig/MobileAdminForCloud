import Foundation

// MARK: - Goodsinfo
struct Goodsinfo :Codable,Identifiable,Hashable{
    var rdt: String?
    let goods: [Good]
    let id: Int?
    let gno: String?
    let kindGb: String?
    var userId: String?
    let registerDt: String?
     
}

// MARK: - Good
struct Good :Codable,Identifiable,Hashable{
    var id:UUID? = UUID()
    let goodsCd: String
    let maxLmt: Int?
    let finProdType:String?
    let goodsNm: String
    let userAlertYn: String?
    let treatmentList: [TreatmentList]?
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
}

// MARK: - BankIemList
struct BankIemList :Codable,Identifiable,Hashable{
    var id:UUID? = UUID()
    let goodsCd: String?
    let iemCodeNm, iemCode: String?
}


// MARK: - GoodsContList
struct GoodsContList :Codable,Identifiable,Hashable{
    var id:UUID? = UUID()
    let sortNo: String?
    let goodsCd: String?
    let msgUseContent, userMsgTitle: String?
}

// MARK: - TreatmentList
struct TreatmentList :Codable,Identifiable,Hashable{
    var id:UUID? = UUID()
    let sortNo: String?
    let goodsCd: String?
    let treatmentCd: String?
    let useYn: String?
    let treatmentNm: String?
}
