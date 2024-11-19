//
//  GroupCodesSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//
import SwiftUI

struct GroupCodesSidebar:View{
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @Binding var groupCodes:[CmmnGroupCodeItem]?
    @Binding var selectedGroupCode:CmmnGroupCodeItem?
    @State var isLoading:Bool = false
    var orderedAscending:[CmmnGroupCodeItem]{
        groupCodes?.sorted(by:{$0.cmmnGroupCode ?? "" < $1.cmmnGroupCode ?? ""}) ?? []
    }
    var body: some View {
        if isLoading {
            ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
        }
        List(selection:$selectedGroupCode){
            ForEach(orderedAscending , id:\.self){  entry in
                NavigationLink(value:entry){
                    HStack {
                        Image(systemName:"doc.text")
                        Text("[\(entry.cmmnGroupCode ?? "")]")
                        Text(entry.cmmnGroupCodeNm ?? "")
                    }//HStack
                }//NavigationLink
            }//ForEach
        }//List
        .toolbar{
            ToolbarItem(placement:.primaryAction){
                Button(action:{
                    Task{
                        isLoading = true
                        groupCodes =  await viewModel.fetchGroupCodeLists()
                        isLoading = false
                    }
                }){
                    Image(systemName:"arrow.clockwise")
                }//Button
            }//ToolbarItem
        }//toolbar
        .navigationTitle("오류 조회")
        .onAppear
        {
            Task{
                isLoading = true
                groupCodes =  await viewModel.fetchGroupCodeLists()
                isLoading = false
            }
        }
    }//body
}//GroupCodesSidebar
