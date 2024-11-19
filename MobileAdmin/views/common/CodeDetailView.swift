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
    
    var body : some View  {
            HStack(alignment:.top){
                VStack{
                    InfoRow(title:"그룹코드", value: cmmnGroupCodeItem.cmmnGroupCode)
                    Divider()
                    InfoRow(title:"그룹코드명", value: cmmnGroupCodeItem.cmmnGroupCodeNm)
                    Divider()
                    InfoRow(title:"사용여부", value: cmmnGroupCodeItem.useAt)
                    Divider()
                    InfoRow(title:"기타항목1", value: cmmnGroupCodeItem.groupEstbs1Value)
                    Divider()
                    InfoRow(title:"기타항목2", value: cmmnGroupCodeItem.groupEstbs2Value)
                    Divider()
                    InfoRow(title:"기타항목3", value: cmmnGroupCodeItem.groupEstbs3Value)
                    Divider()
                    InfoRow(title:"기타항목4", value: cmmnGroupCodeItem.groupEstbs4Value)
                    Divider()
                    InfoRow(title:"기타항목5", value: cmmnGroupCodeItem.groupEstbs5Value)
                    Divider()
                    InfoRow(title:"기타항목6", value: cmmnGroupCodeItem.groupEstbs6Value)
                    Divider()
                    InfoRow(title:"기타항목7", value: cmmnGroupCodeItem.groupEstbs7Value)
                }
                .padding()
            }
            HStack {
                Button("상세코드조회"){
                    Task{
                        isLoading = true;
                        cmmnCodeItems = await viewModel
                            .fetchCodeListByGroupCode(cmmnGroupCodeItem.cmmnGroupCode)
                        isLoading = false;
                    }
                }
            }
        
            .onAppear{
                Task{
                    isLoading = true;
                    cmmnCodeItems = await viewModel
                        .fetchCodeListByGroupCode(cmmnGroupCodeItem.cmmnGroupCode)
                    isLoading = false;
                 
                }
            }
        
            .onChange(of: cmmnGroupCodeItem) {old, newValue in
                Task{
                    isLoading = true;
                    cmmnCodeItems = await viewModel
                        .fetchCodeListByGroupCode(newValue.cmmnGroupCode)
                    isLoading = false;
                 
                }
            }
            Divider()
            
                Table(cmmnCodeItems){
                    TableColumn("코드"     , value:\.cmmnCode )
                    TableColumn("코드명"   , value:\.cmmnCodeNm)
                    TableColumn("사용여부" , value:\.useAt)
                    TableColumn("기타항목1", value:\.cmmnEstbs1Value)
                    TableColumn("기타항목2", value:\.cmmnEstbs2Value)
                    TableColumn("기타항목3", value:\.cmmnEstbs3Value)
                    TableColumn("기타항목4", value:\.cmmnEstbs4Value)
                    TableColumn("기타항목5", value:\.cmmnEstbs5Value)
                    TableColumn("기타항목6", value:\.cmmnEstbs6Value)
                    TableColumn("기타항목7", value:\.cmmnEstbs7Value)
                }
            
    }
}
#Preview(
    traits: .fixedLayout(width: 600, height: 3200)
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
            useAt:"Y"
        ))
}
