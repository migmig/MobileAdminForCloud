//
//  SourceBuildHistory.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/14/25.
//

import SwiftUI

struct SourceBuildHistory: View {
    @ObservedObject var viewModel:ViewModel
    var projectId: Int
    @State var sourceBuildHistoryInfoHistory:[SourceBuildHistoryInfoHistory] = []
    var body: some View {
        List(sourceBuildHistoryInfoHistory, id: \.self){item in
            VStack{
                HStack{
                    Image(systemName:"hammer")
                        .foregroundColor(
                            item.status == "success" ? .green :
                                item.status == "fail" ? .red : .blue
                        )
                    Spacer()
                    Text(item.userId ?? "")
                        .font(.subheadline)
                }
                HStack{
                    Text(Util.convertFromDateIntoString( item.begin ?? 0))
                        .font(.subheadline)
                    Spacer()
                    Text(Util.convertFromDateIntoString( item.end ?? 0))
                        .font(.subheadline)
                }
                HStack{
                    Spacer()
                    Text(item.status ?? "")
                        .font(.subheadline)
                }
            }
        }
        .onAppear(){
            print("history")
            Task{
                let response = await viewModel.fetchSourceBuildHistory(
                    projectId
                )
                sourceBuildHistoryInfoHistory = response?.result?.history ?? []
            }
        }
    }
}

#Preview {
    SourceBuildHistory(viewModel:ViewModel(),
                       projectId:3334)
}
