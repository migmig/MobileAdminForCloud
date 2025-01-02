//
//  CloseDeptSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 12/23/24.
//

import SwiftUI

struct CloseDeptSidebar: View {
    @ObservedObject var viewModel:ViewModel
    @Binding var list:[Detail1]
    @Binding var selectedCloseDept:Detail1?
    @State var closeGb = "4"
    @State var searchText:String = ""
    
    private func filterList() -> [Detail1] {
        list.filter {
            (searchText.isEmpty || $0.deptprtnm?.localizedStandardContains(searchText) == true) &&
            (closeGb == "4" || $0.closegb == closeGb)
        }
    }

    var filteredList: [Detail1] {
        filterList()
    }
    
    private func loadData() async {
       let closeInfo = await viewModel.fetchCloseDeptList()
       list = closeInfo.detail1
   }
    
    private func colorForCloseGb(_ closeGb: String?) -> Color {
        switch closeGb {
        case "1": return .purple
        case "2": return .red
        case "3": return .green
        default: return .blue
        }
    }
     
     var buttonsArr : [[String:String]] = [
                                            ["전체"   : "4" ]
                                          , ["미개시" : ""  ]
                                          , ["개시"   : "0" ]
                                          , ["가마감" : "1" ]
                                          , ["마감"   : "2" ]
                                          , ["마감후거래"   : "3" ]
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
                                .foregroundColor(colorForCloseGb(entry.closegb))
                            Text(entry.deptprtnm ?? "")
                            Spacer()
                            Text(entry.rmk ?? "")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
        }
        .navigationTitle("지점별 개시 마감 조회")
        .navigationSubtitle("\(filteredList.count) 건 조회")
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
