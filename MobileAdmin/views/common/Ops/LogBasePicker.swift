//
//  LogBasePicker.swift
//  MobileAdmin
//
//  NAS 로그 경로(base) 선택 Picker — 사용자 로그(자동 포함) / Backend 로그 공용
//

import SwiftUI

struct LogBasePicker: View {
    var title: String = "로그 경로"
    @Binding var selection: NasLogBase?
    /// true면 맨 앞에 "자동"(nil) 선택지를 둔다
    var allowsAuto: Bool

    var body: some View {
        Picker(title, selection: $selection) {
            if allowsAuto {
                Text("자동").tag(NasLogBase?.none)
            }
            ForEach(NasLogBase.allCases) { base in
                Text(base.title).tag(NasLogBase?.some(base))
            }
        }
        .pickerStyle(.menu)
    }
}

extension LogBasePicker {
    /// "자동" 없이 항상 값이 있는 선택 (Backend 로그)
    init(title: String = "로그 경로", selection: Binding<NasLogBase>) {
        self.init(title: title,
                  selection: Binding<NasLogBase?>(
                    get: { selection.wrappedValue },
                    set: { if let value = $0 { selection.wrappedValue = value } }
                  ),
                  allowsAuto: false)
    }
}

/// @AppStorage에 rawValue로 저장한 base를 바인딩으로 변환 ("" = 자동)
extension Binding where Value == String {
    var nasLogBase: Binding<NasLogBase?> {
        Binding<NasLogBase?>(
            get: { NasLogBase(rawValue: wrappedValue) },
            set: { wrappedValue = $0?.rawValue ?? "" }
        )
    }
}
