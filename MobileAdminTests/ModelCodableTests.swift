//
//  ModelCodableTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
@testable import MobileAdmin

struct ModelCodableTests {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // MARK: - ErrorCloudItem

    @Test func errorCloudItem_emptyInit_setsAllDefaults() {
        let item = ErrorCloudItem()
        #expect(item.id == 0)
        #expect(item.code == "")
        #expect(item.msg == "")
        #expect(item.description == "")
        #expect(item.registerDt == "")
        #expect(item.requestInfo == "")
        #expect(item.restUrl == "")
        #expect(item.traceCn == "")
        #expect(item.userId == "")
    }

    @Test func errorCloudItem_convenienceInit_setsFields() {
        let item = ErrorCloudItem(
            code: "ERR_001",
            description: "Test error",
            id: 42,
            msg: "Something failed",
            registerDt: "2024-10-01T12:00:00",
            requestInfo: "{}",
            restUrl: "/api/test",
            traceCn: "trace content",
            userId: "user123"
        )
        #expect(item.id == 42)
        #expect(item.code == "ERR_001")
        #expect(item.msg == "Something failed")
        #expect(item.userId == "user123")
    }

    @Test func errorCloudItem_codableRoundTrip_preservesAllFields() throws {
        let item = ErrorCloudItem(
            code: "ERR_001",
            description: "Test error",
            id: 42,
            msg: "Something failed",
            registerDt: "2024-10-01",
            requestInfo: "{}",
            restUrl: "/api/test",
            traceCn: "trace content",
            userId: "user123"
        )
        let data = try encoder.encode(item)
        let decoded = try decoder.decode(ErrorCloudItem.self, from: data)
        #expect(decoded.id == item.id)
        #expect(decoded.code == item.code)
        #expect(decoded.msg == item.msg)
        #expect(decoded.userId == item.userId)
        #expect(decoded.restUrl == item.restUrl)
        #expect(decoded.traceCn == item.traceCn)
        #expect(decoded.description == item.description)
    }

    @Test func errorCloudItem_nilOptionals_codableRoundTrip() throws {
        let item = ErrorCloudItem(id: 99)
        let data = try encoder.encode(item)
        let decoded = try decoder.decode(ErrorCloudItem.self, from: data)
        #expect(decoded.id == 99)
        #expect(decoded.code == nil)
        #expect(decoded.msg == nil)
        #expect(decoded.userId == nil)
    }

    @Test func errorCloudItem_hashableConformance_equalItemsMatch() {
        let item1 = ErrorCloudItem(id: 1, msg: "error")
        let item2 = ErrorCloudItem(id: 1, msg: "error")
        #expect(item1 == item2)
    }

    @Test func errorCloudItem_hashableConformance_differentItemsDontMatch() {
        let item1 = ErrorCloudItem(id: 1)
        let item2 = ErrorCloudItem(id: 2)
        #expect(item1 != item2)
    }

    @Test func errorCloudItem_usableInSet() {
        let item1 = ErrorCloudItem(id: 1)
        let item2 = ErrorCloudItem(id: 2)
        let item3 = ErrorCloudItem(id: 1) // duplicate of item1
        let set: Set<ErrorCloudItem> = [item1, item2, item3]
        #expect(set.count == 2)
    }

    // MARK: - Goodsinfo

    @Test func goodsinfo_emptyInit_setsDefaults() {
        let info = Goodsinfo()
        #expect(info.id == 0)
        #expect(info.goods.isEmpty)
        #expect(info.userId == "")
        #expect(info.rdt == "")
        #expect(info.gno == "")
        #expect(info.kindGb == "")
    }

    @Test func goodsinfo_userIdRdtInit_setsFields() {
        let info = Goodsinfo("user1", "20241001")
        #expect(info.userId == "user1")
        #expect(info.rdt == "20241001")
        #expect(info.goods.isEmpty)
    }

    @Test func goodsinfo_userIdRdtGoodsInit_setsGoods() {
        let good = Good("PROD001", "Product A")
        let info = Goodsinfo("user1", "20241001", [good])
        #expect(info.goods.count == 1)
        #expect(info.goods.first?.goodsCd == "PROD001")
    }

    @Test func goodsinfo_fullInit_setsAllFields() {
        let info = Goodsinfo(
            id: 10,
            userid: "userA",
            rdt: "20241001",
            gno: "GNO001",
            kindGb: "K",
            registerDt: "2024-10-01",
            goods: []
        )
        #expect(info.id == 10)
        #expect(info.userId == "userA")
        #expect(info.gno == "GNO001")
        #expect(info.kindGb == "K")
        #expect(info.registerDt == "2024-10-01")
    }

    @Test func goodsinfo_codableRoundTrip() throws {
        let info = Goodsinfo(
            id: 10,
            userid: "userA",
            rdt: "20241001",
            gno: "GNO001",
            kindGb: "K",
            registerDt: "2024-10-01",
            goods: []
        )
        let data = try encoder.encode(info)
        let decoded = try decoder.decode(Goodsinfo.self, from: data)
        #expect(decoded.id == 10)
        #expect(decoded.userId == "userA")
        #expect(decoded.gno == "GNO001")
        #expect(decoded.kindGb == "K")
    }

    // MARK: - Good

    @Test func good_emptyInit_setsDefaults() {
        let good = Good()
        #expect(good.goodsCd == "")
        #expect(good.maxLmt == 0)
        #expect(good.goodsNm == "")
        #expect(good.treatmentList?.isEmpty == true)
        #expect(good.bankIemList?.isEmpty == true)
        #expect(good.goodsContList?.isEmpty == true)
    }

    @Test func good_codeCdInit_setsCodeOnly() {
        let good = Good("PROD001")
        #expect(good.goodsCd == "PROD001")
        #expect(good.goodsNm == "")
        #expect(good.maxLmt == 0)
    }

    @Test func good_codeCdAndNameInit_setsFields() {
        let good = Good("PROD001", "Product Name")
        #expect(good.goodsCd == "PROD001")
        #expect(good.goodsNm == "Product Name")
    }

    @Test func good_codableRoundTrip() throws {
        let good = Good("PROD001", "Product Name", 1000)
        let data = try encoder.encode(good)
        let decoded = try decoder.decode(Good.self, from: data)
        #expect(decoded.goodsCd == "PROD001")
        #expect(decoded.goodsNm == "Product Name")
        #expect(decoded.maxLmt == 1000)
    }

    @Test func good_withTreatmentList_codableRoundTrip() throws {
        let treatment = TreatmentList("1", "PROD001", "TRT01", "Y", "Treatment A")
        let good = Good("PROD001", "Product Name", 500, [treatment])
        let data = try encoder.encode(good)
        let decoded = try decoder.decode(Good.self, from: data)
        #expect(decoded.treatmentList?.count == 1)
        #expect(decoded.treatmentList?.first?.treatmentCd == "TRT01")
    }

    // MARK: - TreatmentList

    @Test func treatmentList_emptyInit_generatesUniqueUUIDs() {
        let t1 = TreatmentList()
        let t2 = TreatmentList()
        #expect(t1.id != nil)
        #expect(t2.id != nil)
        #expect(t1.id != t2.id)
    }

    @Test func treatmentList_emptyInit_setsEmptyStrings() {
        let t = TreatmentList()
        #expect(t.sortNo == "")
        #expect(t.goodsCd == "")
        #expect(t.treatmentCd == "")
        #expect(t.useYn == "")
        #expect(t.treatmentNm == "")
    }

    @Test func treatmentList_paramInit_setsAllFields() {
        let t = TreatmentList("1", "PROD", "TRT01", "Y", "Treatment Name")
        #expect(t.sortNo == "1")
        #expect(t.goodsCd == "PROD")
        #expect(t.treatmentCd == "TRT01")
        #expect(t.useYn == "Y")
        #expect(t.treatmentNm == "Treatment Name")
        #expect(t.id != nil)
    }

    @Test func treatmentList_codableRoundTrip_preservesFields() throws {
        let t = TreatmentList("2", "PROD002", "TRT02", "N", "Another Treatment")
        let data = try encoder.encode(t)
        let decoded = try decoder.decode(TreatmentList.self, from: data)
        #expect(decoded.sortNo == "2")
        #expect(decoded.goodsCd == "PROD002")
        #expect(decoded.treatmentCd == "TRT02")
        #expect(decoded.useYn == "N")
        #expect(decoded.treatmentNm == "Another Treatment")
    }

    // MARK: - BankIemList

    @Test func bankIemList_decodesFromJSON() throws {
        let json = #"{"goodsCd":"PROD","iemCodeNm":"Item Name","iemCode":"CODE01"}"#
        let item = try decoder.decode(BankIemList.self, from: json.data(using: .utf8)!)
        #expect(item.goodsCd == "PROD")
        #expect(item.iemCodeNm == "Item Name")
        #expect(item.iemCode == "CODE01")
    }

    @Test func bankIemList_nullFields_decodesAsNil() throws {
        let json = #"{"goodsCd":null,"iemCodeNm":null,"iemCode":null}"#
        let item = try decoder.decode(BankIemList.self, from: json.data(using: .utf8)!)
        #expect(item.goodsCd == nil)
        #expect(item.iemCodeNm == nil)
        #expect(item.iemCode == nil)
    }

    @Test func bankIemList_codableRoundTrip() throws {
        let json = #"{"goodsCd":"PROD","iemCodeNm":"Name","iemCode":"C01"}"#
        let item = try decoder.decode(BankIemList.self, from: json.data(using: .utf8)!)
        let reEncoded = try encoder.encode(item)
        let decoded = try decoder.decode(BankIemList.self, from: reEncoded)
        #expect(decoded.goodsCd == "PROD")
        #expect(decoded.iemCode == "C01")
    }

    // MARK: - GoodsContList

    @Test func goodsContList_decodesFromJSON() throws {
        let json = #"{"sortNo":"1","goodsCd":"PROD","msgUseContent":"Content","userMsgTitle":"Title"}"#
        let item = try decoder.decode(GoodsContList.self, from: json.data(using: .utf8)!)
        #expect(item.sortNo == "1")
        #expect(item.goodsCd == "PROD")
        #expect(item.msgUseContent == "Content")
        #expect(item.userMsgTitle == "Title")
    }

    @Test func goodsContList_optionalFieldsNull_decodesAsNil() throws {
        let json = #"{"sortNo":null,"goodsCd":null,"msgUseContent":null,"userMsgTitle":null}"#
        let item = try decoder.decode(GoodsContList.self, from: json.data(using: .utf8)!)
        #expect(item.sortNo == nil)
        #expect(item.goodsCd == nil)
    }

    // MARK: - EdcCrseClListResponse

    @Test func edcCrseClListResponse_emptyInit_setsDefaults() {
        let response = EdcCrseClListResponse()
        #expect(response.edcCrseClAllList?.isEmpty == true)
        #expect(response.failCount == 0)
        #expect(response.resultCode == "")
        #expect(response.successCount == 0)
        #expect(response.resultDescription == "")
        #expect(response.resultMsg == "")
    }

    @Test func edcCrseClListResponse_decodesFromJSON_emptyList() throws {
        let json = """
        {
            "edcCrseClAllList": [],
            "failCount": 0,
            "resultCode": "0000",
            "successCount": 0,
            "resultDescription": "Success",
            "resultMsg": "OK"
        }
        """
        let response = try decoder.decode(EdcCrseClListResponse.self, from: json.data(using: .utf8)!)
        #expect(response.resultCode == "0000")
        #expect(response.successCount == 0)
        #expect(response.edcCrseClAllList?.isEmpty == true)
    }

    @Test func edcCrseClListResponse_decodesFromJSON_withItems() throws {
        let json = """
        {
            "edcCrseClAllList": [
                {
                    "edcStartDt": "2024-01-01",
                    "lctreIntrcn": "Introduction",
                    "edcCrseThumb": "",
                    "frstRegisterId": "admin",
                    "lrnRcognTime": 60,
                    "edcCrseId": 1,
                    "edcEndDt": "2024-12-31",
                    "lastRegisterId": "admin",
                    "evlScore": 4.5,
                    "rmkCount": 0,
                    "edcCrseName": "Swift 기초",
                    "edcPDMonth": 12,
                    "gcpEdcCategoryList": [],
                    "rmkYn": "N",
                    "edcComplExpireMonth": 6
                }
            ],
            "failCount": 0,
            "resultCode": "0000",
            "successCount": 1,
            "resultDescription": "Success",
            "resultMsg": "OK"
        }
        """
        let response = try decoder.decode(EdcCrseClListResponse.self, from: json.data(using: .utf8)!)
        #expect(response.edcCrseClAllList?.count == 1)
        #expect(response.edcCrseClAllList?.first?.edcCrseName == "Swift 기초")
        #expect(response.successCount == 1)
    }

    // MARK: - EdcCrseCl

    @Test func edcCrseCl_emptyInit_setsDefaults() {
        let course = EdcCrseCl()
        #expect(course.edcCrseId == 0)
        #expect(course.edcCrseName == "")
        #expect(course.gcpEdcCategoryList?.isEmpty == true)
        #expect(course.lrnRcognTime == 0)
    }

    @Test func edcCrseCl_idProperty_returnsEdcCrseId() {
        let course = EdcCrseCl(edcCrseId: 99, edcCrseName: "Test Course", lcteIntrcn: "Intro")
        #expect(course.id == 99)
    }

    @Test func edcCrseCl_nameAndIntrcnInit_setsFields() {
        let course = EdcCrseCl("Course Name", "Course Introduction")
        #expect(course.edcCrseName == "Course Name")
        #expect(course.lctreIntrcn == "Course Introduction")
        #expect(course.edcCrseId == 0)
    }

    @Test func edcCrseCl_codableRoundTrip() throws {
        let course = EdcCrseCl(edcCrseId: 5, edcCrseName: "Swift Course", lcteIntrcn: "Learn Swift")
        let data = try encoder.encode(course)
        let decoded = try decoder.decode(EdcCrseCl.self, from: data)
        #expect(decoded.edcCrseId == 5)
        #expect(decoded.edcCrseName == "Swift Course")
        #expect(decoded.lctreIntrcn == "Learn Swift")
    }

    // MARK: - CmmnGroupCodeItem

    @Test func cmmnGroupCodeItem_codableRoundTrip() throws {
        let json = """
        {
            "cmmnGroupCode": "GRP001",
            "cmmnGroupCodeNm": "Group Name",
            "groupEstbs1Value": "val1",
            "groupEstbs2Value": null,
            "groupEstbs3Value": null,
            "groupEstbs4Value": null,
            "groupEstbs5Value": null,
            "groupEstbs6Value": null,
            "groupEstbs7Value": null,
            "useAt": "Y"
        }
        """
        let item = try decoder.decode(CmmnGroupCodeItem.self, from: json.data(using: .utf8)!)
        #expect(item.cmmnGroupCode == "GRP001")
        #expect(item.cmmnGroupCodeNm == "Group Name")
        #expect(item.groupEstbs1Value == "val1")
        #expect(item.groupEstbs2Value == nil)
        #expect(item.useAt == "Y")
    }

    @Test func cmmnGroupCodeItem_hashableConformance() {
        let json = """
        {"cmmnGroupCode":"GRP001","cmmnGroupCodeNm":null,"groupEstbs1Value":null,
         "groupEstbs2Value":null,"groupEstbs3Value":null,"groupEstbs4Value":null,
         "groupEstbs5Value":null,"groupEstbs6Value":null,"groupEstbs7Value":null,"useAt":null}
        """
        let item = try? decoder.decode(CmmnGroupCodeItem.self, from: json.data(using: .utf8)!)
        #expect(item != nil)
        let set: Set<CmmnGroupCodeItem> = [item!, item!]
        #expect(set.count == 1)
    }

    // MARK: - CmmnCodeItem

    @Test func cmmnCodeItem_decodesWithNestedIdObject() throws {
        let json = """
        {
            "cmmnCodeNm": "Test Code",
            "cmmnEstbs1Value": "v1",
            "cmmnEstbs2Value": "v2",
            "cmmnEstbs3Value": "",
            "cmmnEstbs4Value": "",
            "cmmnEstbs5Value": "",
            "cmmnEstbs6Value": "",
            "cmmnEstbs7Value": "",
            "id": {
                "cmmnCode": "CODE01",
                "cmmnGoupCode": "GRP001"
            },
            "sortOrdr": 1,
            "upperCmmnCode": "UPPER",
            "useAt": "Y"
        }
        """
        let item = try decoder.decode(CmmnCodeItem.self, from: json.data(using: .utf8)!)
        #expect(item.cmmnCodeNm == "Test Code")
        #expect(item.cmmnCode == "CODE01")
        #expect(item.cmmnGoupCode == "GRP001")
        #expect(item.id == "CODE01")
        #expect(item.sortOrdr == 1)
        #expect(item.upperCmmnCode == "UPPER")
        #expect(item.useAt == "Y")
    }

    @Test func cmmnCodeItem_missingOptionalFields_defaultsToEmpty() throws {
        let json = """
        {
            "cmmnCodeNm": "Test Code",
            "id": {
                "cmmnCode": "CODE01",
                "cmmnGoupCode": "GRP001"
            },
            "sortOrdr": 1
        }
        """
        let item = try decoder.decode(CmmnCodeItem.self, from: json.data(using: .utf8)!)
        #expect(item.cmmnEstbs1Value == "")
        #expect(item.cmmnEstbs2Value == "")
        #expect(item.cmmnEstbs3Value == "")
        #expect(item.upperCmmnCode == "")
        #expect(item.useAt == "")
    }

    @Test func cmmnCodeItem_idProxyProperties_exposeNestedValues() throws {
        let json = """
        {
            "cmmnCodeNm": "Code",
            "id": {"cmmnCode": "C1", "cmmnGoupCode": "G1"},
            "sortOrdr": 0
        }
        """
        let item = try decoder.decode(CmmnCodeItem.self, from: json.data(using: .utf8)!)
        // id computed property returns cmmnCode
        #expect(item.id == item.cmmnCode)
        // cmmnGoupCode proxy
        #expect(item.cmmnGoupCode == "G1")
    }

    // MARK: - Toast

    @Test func toast_nilValues_usesDefaultEmptyStrings() {
        let toast = Toast(
            applcBeginDt: nil,
            applcEndDt: nil,
            noticeHder: nil,
            noticeSj: nil,
            noticeCn: nil,
            useYn: nil
        )
        #expect(toast.noticeHder == "")
        #expect(toast.noticeSj == "")
        #expect(toast.noticeCn == "")
        #expect(toast.useYn == "")
    }

    @Test func toast_nilDates_usesCurrentDate() {
        let before = Date()
        let toast = Toast(applcBeginDt: nil, applcEndDt: nil, noticeHder: nil,
                          noticeSj: nil, noticeCn: nil, useYn: nil)
        let after = Date()
        #expect(toast.applcBeginDt >= before)
        #expect(toast.applcBeginDt <= after)
    }

    @Test func toast_codableRoundTrip_preservesStrings() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let toast = Toast(
            applcBeginDt: fixedDate,
            applcEndDt: fixedDate,
            noticeHder: "Header",
            noticeSj: "Subject",
            noticeCn: "Content body",
            useYn: "Y"
        )
        let data = try encoder.encode(toast)
        let decoded = try decoder.decode(Toast.self, from: data)
        #expect(decoded.noticeHder == "Header")
        #expect(decoded.noticeSj == "Subject")
        #expect(decoded.noticeCn == "Content body")
        #expect(decoded.useYn == "Y")
    }

    @Test func toast_codableRoundTrip_preservesDates() throws {
        let beginDt = Date(timeIntervalSince1970: 1_700_000_000)
        let endDt   = Date(timeIntervalSince1970: 1_700_100_000)
        let toast = Toast(applcBeginDt: beginDt, applcEndDt: endDt,
                          noticeHder: nil, noticeSj: nil, noticeCn: nil, useYn: nil)
        let data = try encoder.encode(toast)
        let decoded = try decoder.decode(Toast.self, from: data)
        #expect(abs(decoded.applcBeginDt.timeIntervalSince(beginDt)) < 0.001)
        #expect(abs(decoded.applcEndDt.timeIntervalSince(endDt)) < 0.001)
    }

    @Test func toast_hashableConformance_equalToastsMatch() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let t1 = Toast(applcBeginDt: date, applcEndDt: date, noticeHder: "H",
                       noticeSj: "S", noticeCn: "C", useYn: "Y")
        let t2 = Toast(applcBeginDt: date, applcEndDt: date, noticeHder: "H",
                       noticeSj: "S", noticeCn: "C", useYn: "Y")
        #expect(t1 == t2)
    }
}
