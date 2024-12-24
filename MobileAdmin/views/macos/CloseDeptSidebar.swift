//
//  CloseDeptSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 12/23/24.
//

import SwiftUI

struct CloseDeptSidebar: View {
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @Binding var closeDeptList:[Detail1] 
    @Binding var selectedCloseDept:Detail1?
    var body: some View {
        List(selection: $selectedCloseDept){
            ForEach(closeDeptList, id:\.self){ close in
                NavigationLink(value:close){
                    HStack{
                        Image(systemName: close.closegb == "0" ? "checkmark.circle" : "circle")
                        Text(close.deptprtnm ?? "")
                        Spacer()
                        Text(close.rmk ?? "")
                    }
                }
            }
        }
        
        .onAppear(){
            Task{ 
                let closeInfo:CloseInfo = await viewModel.fetchCloseDeptList();
                closeDeptList = closeInfo.detail1
                print("\(String(describing: closeInfo))")
            }
        }
    }
}

#Preview {
    CloseDeptSidebar(
        viewModel: ViewModel(),
        closeDeptList: .constant([]),
        selectedCloseDept: .constant(nil)
    )
}
