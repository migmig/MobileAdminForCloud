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
    @State var closeGb = "4"
    init(viewModel:ViewModel){
        self.viewModel = viewModel
    }
    
    var filteredList: [Detail1] {
        closeGb == "4" ? list : list.filter{$0.closegb == closeGb}
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
        
        NavigationStack {
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
                List(filteredList){entry in
                    //ForEach(filteredList, id:\.self){
                    NavigationLink(destination: {
                        CloseDeptDetail(closeDetail: entry)
                    }){
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
                    //}
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
}


struct ButtonView: View {
    var txt:String
    var selectGb:String
    @Binding var closeGb:String
    var loadData: () async -> Void
    var body: some View {
        Button(txt, action: {
            Task{
                closeGb = selectGb
                await loadData()
            }
        })
        .buttonStyle(BorderedButtonStyle())
    }
}

#Preview {
    CloseDeptListViewIOS(viewModel: ViewModel())
}
