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
        EnvironmentConfig.current = .local
        let toast = await viewModel.fetchToasts()
         print("Toast 데이터: \(toast)")
         
        logger.info("test end")
        #expect(toast != nil)
        //  #expect(toast?.applcBeginDt.contains("T") == false)
    }
    @Test func getClsLists() async throws{
        EnvironmentConfig.current = .local
        viewModel.setToken(token: nil)
        let clsLists = await viewModel.fetchClsLists()
        print("clsLists 데이터: \(clsLists)")
        #expect(clsLists != nil)
    }
}
