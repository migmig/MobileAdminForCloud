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
        switch status {
        case "success":
            return .blue
        case "fail":
            return .red
        case "upload":
            return .purple
        case "canceled":
            return .pink
        default:
            return .gray
        }
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
                        .font(.system(size: 11))
                    Spacer()
                    Text(Util.convertFromDateIntoString( item.end ?? 0))
                        .font(.system(size: 11))
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
