//
//  MobileAdminTests.swift
//  MobileAdminTests
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import Testing
import Logging
@testable import MobileAdmin

struct MobileAdminTests {

    let logger = Logger(label:"com.migmig.MobileAdmin.MobileAdminTests")
    var viewModel = ViewModel()

    @Test func fetchToastsTest() async throws {
        let toast = await viewModel.fetchToasts()
        if let toast = toast {
            print("Toast 데이터: \(toast)")
        } else {
            print("Toast 데이터를 가져오는 데 실패했습니다.")
        }
        logger.info("test end")
        #expect(toast != nil)
        //  #expect(toast?.applcBeginDt.contains("T") == false)
    }

    @Test func setToastsTest() async throws {
        let toast = await viewModel.fetchToasts()
        if let toast = toast {
            print("Toast 데이터: \(toast)")
        } else {
            print("Toast 데이터를 가져오는 데 실패했습니다.")
        }

        #expect(toast != nil)
      //  #expect(toast?.applcBeginDt.contains("T") == false)
    }
}
