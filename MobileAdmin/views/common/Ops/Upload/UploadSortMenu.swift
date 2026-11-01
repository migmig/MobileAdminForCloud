//
//  UploadSortMenu.swift
//  MobileAdmin
//
//  업로드 목록 정렬 메뉴 (디렉터리는 항상 먼저)
//

import SwiftUI

struct UploadSortMenu: View {
    @Binding var sort: UploadSort
    @Binding var ascending: Bool

    var body: some View {
        Menu {
            Picker("정렬 기준", selection: $sort) {
                ForEach(UploadSort.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            if sort != .server {
                Picker("순서", selection: $ascending) {
                    Text("오름차순").tag(true)
                    Text("내림차순").tag(false)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .help("정렬")
        .accessibilityLabel("정렬")
    }
}
