//
//  CodeListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//

import SwiftUI

struct CodeListViewIOS: View {
    @ObservedObject var viewModel:ViewModel
    @State var cmmnGroupCodeItems:[CmmnGroupCodeItem] = []
    var body: some View {
        //NavigationStack{
            VStack{
                List{
                    ForEach(cmmnGroupCodeItems,id:\.self){ item in
                        NavigationLink(destination: CodeDetailView(viewModel: viewModel, cmmnGroupCodeItem: item)){
                            HStack {
                                Image(systemName:"doc.text")
                                Text("[\(item.cmmnGroupCode)]")
                                Text(item.cmmnGroupCodeNm ?? "")
                            }//HStack
                        }
                    }
                }
            }
            .navigationTitle("코드 조회")
       // }
        .onAppear(){
            if cmmnGroupCodeItems.isEmpty{
                Task{
                    cmmnGroupCodeItems = await viewModel.fetchGroupCodeLists()
                }
            }
        }
    }
}

#Preview {
    CodeListViewIOS(viewModel: ViewModel())
}
