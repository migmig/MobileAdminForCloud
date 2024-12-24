 
import Foundation

struct CloseInfo : Codable {
    let detail1: [Detail1]
    init(){
        detail1 = []
    }
}

struct Detail1 : Codable  ,Identifiable,Hashable{
    let closeempno,rmk,deptprtnm, closegb, closetime, opentime,deptcd: String?
    var id: String{
        return self.deptcd ?? ""
    }
}
