//
//  CloseDeptSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 12/23/24.
//

import SwiftUI

struct CloseDeptSidebar: View {
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @Binding var list:[Detail1]
    @Binding var selectedCloseDept:Detail1?
    @State var closeGb = "4"
    
    
    var filteredList: [Detail1] {
        closeGb  == "4" ? list : list.filter{$0.closegb == closeGb}
    }
    
    private func loadData() async {
       let closeInfo = await viewModel.fetchCloseDeptList()
       list = closeInfo.detail1
   }
    
     
     var buttonsArr : [[String:String]] = [
                                            ["전체"   : "4" ]
                                          , ["미개시" : ""  ]
                                          , ["개시"   : "0" ]
                                          , ["가마감" : "1" ]
                                          , ["마감"   : "2" ]
                                         ]
    
    var body: some View {
        VStack{
            HStack {
                ForEach(buttonsArr, id:\.self){ button in
                    ButtonView(txt: button.keys.first!
                               , selectGb: button.values.first!
                               , closeGb: $closeGb
                               , loadData: loadData)
                }
            }
            .padding()
            List(selection: $selectedCloseDept){
                ForEach(filteredList, id:\.self){ entry in
                    NavigationLink(value:entry){
                        HStack{
                            Image(systemName: entry.closegb != "" ? "checkmark.circle" : "circle")
                                .colorMultiply(  entry.closegb == "1" ? .purple
                                               : entry.closegb == "2" ? .red
                                               : .green)
                            Text(entry.deptprtnm ?? "")
                            Spacer()
                            Text(entry.rmk ?? "")
                        }
                    }
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
    CloseDeptSidebar(
        viewModel: ViewModel(),
        list: .constant([]),
        selectedCloseDept: .constant(nil)
    )
}
