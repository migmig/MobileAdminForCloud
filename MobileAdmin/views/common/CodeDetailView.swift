//
//  CodeDetailView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//
import SwiftUI

struct CodeDetailView:View{
    @ObservedObject var viewModel : ViewModel
    var cmmnGroupCodeItem:CmmnGroupCodeItem
    @State var isLoading:Bool = false
    @State var cmmnCodeItems:[CmmnCodeItem] = []

    fileprivate func fnSearch()  {
        Task{
            withAnimation{
                isLoading = true;
            }
            cmmnCodeItems = await viewModel.fetchCodeListByGroupCode(cmmnGroupCodeItem.cmmnGroupCode)

            withAnimation{
                isLoading = false;
            }
        }
    }
    var body : some View  {
        ScrollView{
            VStack(spacing: AppSpacing.md) {
                // 그룹코드 기본 정보
                CardView(title: "그룹코드", systemImage: "number") {
                    InfoRow(title:"그룹코드", value: cmmnGroupCodeItem.cmmnGroupCode)
                    InfoRow(title:"그룹코드명", value: cmmnGroupCodeItem.cmmnGroupCodeNm)
                    InfoRowCustom(title:"사용여부"){
                        Toggle(isOn: .constant(cmmnGroupCodeItem.useAt == "Y")){
                            Text(cmmnGroupCodeItem.useAt == "Y" ? "사용":"미사용")
                        }
                    }
                }

#if os(macOS)
                // 기타항목 (macOS만)
                CardView(title: "기타 항목", systemImage: "list.bullet.rectangle") {
                    InfoRow(title:"기타항목1", value: cmmnGroupCodeItem.groupEstbs1Value)
                    InfoRow(title:"기타항목2", value: cmmnGroupCodeItem.groupEstbs2Value)
                    InfoRow(title:"기타항목3", value: cmmnGroupCodeItem.groupEstbs3Value)
                    InfoRow(title:"기타항목4", value: cmmnGroupCodeItem.groupEstbs4Value)
                    InfoRow(title:"기타항목5", value: cmmnGroupCodeItem.groupEstbs5Value)
                    InfoRow(title:"기타항목6", value: cmmnGroupCodeItem.groupEstbs6Value)
                    InfoRow(title:"기타항목7", value: cmmnGroupCodeItem.groupEstbs7Value)
                }
#endif

                // 조회 버튼
                Button(action: { fnSearch() }) {
                    Label("상세코드조회", systemImage: "magnifyingglass")
                }
                .buttonStyle(.bordered)

                // 상세코드 테이블
                if isLoading {
                    ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
                } else if cmmnCodeItems.isEmpty {
                    EmptyStateView(
                        systemImage: "doc.text.magnifyingglass",
                        title: "코드 데이터 없음",
                        description: "상세코드조회 버튼을 눌러 조회하세요"
                    )
                } else {
                    ScrollView(.horizontal, showsIndicators: true){
                        VStack(spacing: 0) {
                            // 헤더
                            HStack{
                                Text("코드").frame(width:100)
                                Text("코드명").frame(width:200)
                                Text("사용여부").frame(width:80)
                                Text(cmmnGroupCodeItem.groupEstbs1Value ?? "기타항목1").frame(width:150)
                                Text(cmmnGroupCodeItem.groupEstbs2Value ?? "기타항목2").frame(width:150)
                                Text(cmmnGroupCodeItem.groupEstbs3Value ?? "기타항목3").frame(width:150)
                                Text(cmmnGroupCodeItem.groupEstbs4Value ?? "기타항목4").frame(width:150)
                                Text(cmmnGroupCodeItem.groupEstbs5Value ?? "기타항목5").frame(width:150)
                                Text(cmmnGroupCodeItem.groupEstbs6Value ?? "기타항목6").frame(width:150)
                                Text(cmmnGroupCodeItem.groupEstbs7Value ?? "기타항목7").frame(width:150)
                            }
                            .fontWeight(.bold)
                            .font(AppFont.caption)
                            .padding(.vertical, AppSpacing.sm)
                            #if os(iOS)
                            .background(Color(.tertiarySystemGroupedBackground))
                            #else
                            .background(Color(.controlBackgroundColor))
                            #endif
                            .cornerRadius(8)

                            // 데이터 행
                            ForEach(cmmnCodeItems){item in
                                HStack{
                                    Text(item.cmmnCode).frame(width:100)
                                    Text(item.cmmnCodeNm).frame(width:200)
                                    Toggle(isOn: .constant(item.useAt == "Y")){}.frame(width:80)
                                    Text(item.cmmnEstbs1Value).frame(width:150)
                                    Text(item.cmmnEstbs2Value).frame(width:150)
                                    Text(item.cmmnEstbs3Value).frame(width:150)
                                    Text(item.cmmnEstbs4Value).frame(width:150)
                                    Text(item.cmmnEstbs5Value).frame(width:150)
                                    Text(item.cmmnEstbs6Value).frame(width:150)
                                    Text(item.cmmnEstbs7Value).frame(width:150)
                                }
                                .font(AppFont.caption)
                                .padding(.vertical, AppSpacing.xs)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("코드상세조회")
        .onAppear{
            fnSearch()
        }
        .onChange(of: cmmnGroupCodeItem) {old, newValue in
            fnSearch()
        }
    }
}
#Preview(
    traits: .fixedLayout(width: 600, height: 1200)
){
    CodeDetailView(
        viewModel: ViewModel(),
        cmmnGroupCodeItem: CmmnGroupCodeItem(
            cmmnGroupCode: "8005",
            cmmnGroupCodeNm: "그룹코드명",
            groupEstbs1Value: "그룹코드설명",
            groupEstbs2Value: "사용여부",
            groupEstbs3Value: "등록자",
            groupEstbs4Value: "등록일",
            groupEstbs5Value: "수정자",
            groupEstbs6Value: "수정일",
            groupEstbs7Value: "수정일",
            useAt:"N"
        ))
}
