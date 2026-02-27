//
//  EdcCrseListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/11/24.
//

import SwiftUI

struct EdcCrseListViewIOS: View {
    @EnvironmentObject var educationViewModel: EducationViewModel
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    EdcCrseListViewIOS()
        .environmentObject(EducationViewModel())
}
