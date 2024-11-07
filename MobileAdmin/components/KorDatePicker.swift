//
//  KorDatePicker.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/4/24.
//

import SwiftUI

struct KorDatePicker: View {
    var title:String
    @Binding var selection:Date
    var displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]
    init(
        _ title:String,
        selection:Binding<Date>,
        displayedComponents:DatePickerComponents =  [.hourAndMinute, .date]
    ) {
        self.title = title
        self._selection = selection
        self.displayedComponents = displayedComponents
    }
    var body: some View {
        DatePicker(title,
                   selection: $selection,
                   displayedComponents: displayedComponents
        )
        .environment(\.locale, Locale(identifier: "ko_KR"))
    }
}

#Preview {
    KorDatePicker("From", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
    KorDatePicker("To", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
}
