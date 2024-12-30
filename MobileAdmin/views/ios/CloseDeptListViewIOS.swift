//
//  CodeListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/19/24.
//

import SwiftUI

struct CloseDeptListViewIOS: View {
    @ObservedObject var viewModel:ViewModel
    @State var list:[Detail1] = []
    
    private func loadData() async {
       let closeInfo = await viewModel.fetchCloseDeptList()
       list = closeInfo.detail1
   }
    var body: some View {
        VStack{
            List{
                ForEach(list, id:\.self){ close in
                    NavigationLink(destination: {
                        CloseDeptDetail(closeDetail: close)
                    }){
                        HStack{
                            Image(systemName: close.closegb == "0" ? "checkmark.circle" : "circle")
                            Text(close.deptprtnm ?? "")
                            Spacer()
                            Text(close.rmk ?? "")
                        }
                    }
                }
            }
            .refreshable {
                Task{
                    await loadData()
                }
            }
        }
        .onAppear(){
            Task{
                await loadData()
            }
        }
    }
}

#Preview {
    CloseDeptListViewIOS(viewModel: ViewModel())
}
