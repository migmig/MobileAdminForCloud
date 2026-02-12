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
    func getBuildColor(status:String) -> Color{
        return AppColor.buildStatus(status)
    }
    
    var body: some View {
        List(sourceBuildHistoryInfoHistory, id: \.self){item in
            VStack{
                HStack{
                    Image(systemName:"hammer")
                        .foregroundColor(getBuildColor(status: item.status ?? ""))
                    Spacer()
                    Text(item.userId ?? "")
                        .font(.subheadline)
                }
                HStack{
                    Text(Util.convertFromDateIntoString( item.begin ?? 0))
                        .font(AppFont.timestamp)
                    Spacer()
                    Text(Util.convertFromDateIntoString( item.end ?? 0))
                        .font(AppFont.timestamp)
                }
                HStack{
                    Spacer()
                    Text(item.status ?? "")
                        .font(.subheadline)
                        .foregroundColor(getBuildColor(status: item.status ?? ""))
                }
            }
        }
        .onAppear(){
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
