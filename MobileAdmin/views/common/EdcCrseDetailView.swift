//
//  EdcCrseDetailView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/8/24.
//

import SwiftUI

struct EdcCrseDetailView: View {
    @EnvironmentObject var educationViewModel: EducationViewModel
    var edcCrseClinfo : EdcCrseCl

    var body: some View {
        ScrollView{
            VStack(spacing: AppSpacing.md) {
                // 썸네일 + 기본 정보
                CardView(title: "교육과정", systemImage: "book") {
                    InfoRow(title: "ID", value: String(edcCrseClinfo.edcCrseId!))
                    InfoRow(title: "교육과정 분류 명", value: edcCrseClinfo.edcCrseName)
                    InfoRowCustom(title: "카테고리"){
                        ForEach(edcCrseClinfo.gcpEdcCategoryList ?? [], id: \.self){
                             Text($0.categoryName ?? "")
                                .foregroundColor(.secondary)
                         }
                    }
                    InfoRowCustom(title: "썸네일"){
                        if let url = URL(string: edcCrseClinfo.edcCrseThumb ?? ""){
                            AsyncImage(url: url){img in
                                img.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }.frame(maxWidth:200)
                                .cornerRadius(8)
                        }
                    }
                }

                // 기간 정보
                CardView(title: "교육 기간", systemImage: "calendar") {
                    InfoRow(title: "교육기간 시작", value: Util.convertToFormattedDate(edcCrseClinfo.edcStartDt))
                    InfoRow(title: "교육기간 종료", value: Util.convertToFormattedDate(edcCrseClinfo.edcEndDt))
                    InfoRow(title: "학습기간 (월)", value: String(edcCrseClinfo.edcPDMonth ?? 0))
                    InfoRow(title: "학습인정시간(시)", value: String(edcCrseClinfo.lrnRcognTime ?? 0) + "시간")
                    InfoRow(title: "수료만기개월수", value: String(edcCrseClinfo.edcComplExpireMonth ?? 0))
                }

                // 기타 정보
                CardView(title: "강의 정보", systemImage: "text.book.closed") {
                    InfoRow(title: "강의 소개", value: edcCrseClinfo.lctreIntrcn)
                    InfoRow(title: "등록일", value: Util.convertToFormattedDate(edcCrseClinfo.edcStartDt))
                    InfoRowCustom(title: "회차정보"){
                        NavigationLink(
                            destination: EdcEducationCrseInfoDetail(
                                edcCrseId: edcCrseClinfo.edcCrseId!
                            )
                        ){
                            Text("상세보기")
                        }
                    }
                }
            }
            .padding()
        }
    }
}
#Preview
{
    EdcCrseDetailView(edcCrseClinfo: EdcCrseCl())
        .environmentObject(EducationViewModel())
}
