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
            HStack(alignment:.top){
                VStack{
                    InfoRow(title:"그룹코드", value: cmmnGroupCodeItem.cmmnGroupCode)
                    Divider()
                    InfoRow(title:"그룹코드명", value: cmmnGroupCodeItem.cmmnGroupCodeNm)
                    Divider()
                    InfoRow2(title:"사용여부"){
                        Toggle(isOn: .constant(cmmnGroupCodeItem.useAt == "Y")){
                            Text(cmmnGroupCodeItem.useAt == "Y" ? "사용":"미사용")
                        }
                    }
#if os(macOS)
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
#endif
                }
                .padding()
            }
            HStack {
                Button("상세코드조회"){
                    fnSearch()
                }
            }
            
            .onAppear{
                fnSearch()
            }
            
            .onChange(of: cmmnGroupCodeItem) {old, newValue in
                fnSearch()
            }
            Divider()
//#if os(macOS)
//            Table(cmmnCodeItems){
//                TableColumn("코드"     , value:\.cmmnCode )
//                TableColumn("코드명"   , value:\.cmmnCodeNm)
//                TableColumn("사용여부" , value:\.useAt)
//                TableColumn(cmmnGroupCodeItem.groupEstbs1Value ?? "기타항목1", value:\.cmmnEstbs1Value)
//                TableColumn(cmmnGroupCodeItem.groupEstbs2Value ?? "기타항목2", value:\.cmmnEstbs2Value)
//                TableColumn(cmmnGroupCodeItem.groupEstbs3Value ?? "기타항목3", value:\.cmmnEstbs3Value)
//                TableColumn(cmmnGroupCodeItem.groupEstbs4Value ?? "기타항목4", value:\.cmmnEstbs4Value)
//                TableColumn(cmmnGroupCodeItem.groupEstbs5Value ?? "기타항목5", value:\.cmmnEstbs5Value)
//                TableColumn(cmmnGroupCodeItem.groupEstbs6Value ?? "기타항목6", value:\.cmmnEstbs6Value)
//                TableColumn(cmmnGroupCodeItem.groupEstbs7Value ?? "기타항목7", value:\.cmmnEstbs7Value)
//            }
//#endif
//#if os(iOS)
            if(isLoading){
                ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
            }else{
                ScrollView(.horizontal, showsIndicators: true){
                    
                    HStack{
                        VStack{
                            Text("코드")
                        }
                        .frame(width:100)
                        VStack{
                            Text("코드명")
                        }
                        .frame(width:200)
                        VStack{
                            Text("사용여부")
                        }
                        .frame(width:80)
                        VStack{
                            Text(cmmnGroupCodeItem.groupEstbs1Value ?? "기타항목1")
                        }
                        .frame(width:150)
                        VStack{
                            Text(cmmnGroupCodeItem.groupEstbs2Value ?? "기타항목2")
                        }
                        .frame(width:150)
                        VStack{
                            Text(cmmnGroupCodeItem.groupEstbs3Value ?? "기타항목3")
                        }
                        .frame(width:150)
                        VStack{
                            Text(cmmnGroupCodeItem.groupEstbs4Value ?? "기타항목4")
                        }
                        .frame(width:150)
                        VStack{
                            Text(cmmnGroupCodeItem.groupEstbs5Value ?? "기타항목5")
                        }
                        .frame(width:150)
                        VStack{
                            Text(cmmnGroupCodeItem.groupEstbs6Value ?? "기타항목6")
                        }
                        .frame(width:150)
                        VStack{
                            Text(cmmnGroupCodeItem.groupEstbs7Value ?? "기타항목7")
                        }
                        .frame(width:150)
                    }
                    .fontWeight(.bold)
                    Divider()
                    ForEach(cmmnCodeItems){item in
                        HStack{
                            VStack{
                                Text(item.cmmnCode)
                            }
                            .frame(width:100)
                            VStack{
                                Text(item.cmmnCodeNm)
                                // .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width:200)
                            VStack{
                                Toggle(isOn: .constant(item.useAt == "Y")){}
                            }
                            .frame(width:80)
                            VStack{
                                Text(item.cmmnEstbs1Value)
                                // .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width:150)
                            VStack{
                                Text(item.cmmnEstbs1Value)
                                // .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width:150)
                            VStack{
                                Text(item.cmmnEstbs3Value)
                                // .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width:150)
                            VStack{
                                Text(item.cmmnEstbs4Value)
                                // .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width:150)
                            VStack{
                                Text(item.cmmnEstbs5Value)
                                // .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width:150)
                            VStack{
                                Text(item.cmmnEstbs6Value)
                                // .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width:150)
                            VStack{
                                Text(item.cmmnEstbs7Value)
                                // .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width:150)
                        }
                    }
                }
            }
//#endif
        }
        .navigationTitle("코드상세조회")
            
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
