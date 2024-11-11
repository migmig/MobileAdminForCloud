//
//  EdcCrseDetailView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/8/24.
//

import SwiftUI

struct EdcCrseDetailView: View {
    @ObservedObject var viewModel : ViewModel
    var edcCrseClinfo : EdcCrseCl
//    init(
//        viewModel: ViewModel,_ edcCrseClinfo:EdcCrseCl){
//        self.viewModel = viewModel
//        self.edcCrseClinfo = edcCrseClinfo
//    }
    var body: some View {
        ScrollView{
            LazyVStack{
                InfoRow(title: "ID", value: String(edcCrseClinfo.edcCrseId!))
                Divider()
                InfoRow2(title: "카테고리"){
                    ForEach(edcCrseClinfo.gcpEdcCategoryList ?? [], id: \.self){
                         Text($0.categoryName ?? "")
                            .foregroundColor(.secondary)
                     }
                }
                Divider()
                InfoRow(title: "교육과정 분류 명", value: edcCrseClinfo.edcCrseName)
                Divider()
                InfoRow2(title: "썸네일"){
                    AsyncImage(
                        url: URL(string: edcCrseClinfo.edcCrseThumb ?? "")
                    ){img in
                         img.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }.frame(maxWidth:200)
                }
                Divider()
                InfoRow2(title: "회차정보"){
                    NavigationLink(
                        destination: EdcEducationCrseInfoDetail(
                            viewModel:viewModel,
                            edcCrseId: edcCrseClinfo.edcCrseId!
                        )
                    ){
                        Text("상세보기")
                    }
                }
                Divider()
                InfoRow(title: "교육기간_from", value: Util.convertToFormattedDate(edcCrseClinfo.edcStartDt  ))
                Divider()
                InfoRow(title: "교육기간_to", value:  Util.convertToFormattedDate(edcCrseClinfo.edcEndDt ))
                Divider()
                InfoRow(title: "학습기간 (월)", value: String(edcCrseClinfo.edcPDMonth ?? 0))
                Divider()
                InfoRow(title: "학습인정시간(시)", value: String(edcCrseClinfo.lrnRcognTime ?? 0) + "분")
                Divider()
                InfoRow(title: "강의 소개", value: edcCrseClinfo.lctreIntrcn)
                Divider()
                InfoRow(title: "등록일", value: Util.convertToFormattedDate(edcCrseClinfo.edcStartDt))
                Divider()
                InfoRow(title: "수료만기개월수", value: String(edcCrseClinfo.edcComplExpireMonth ?? 0))
            }
            .padding()
        }
    }
}
