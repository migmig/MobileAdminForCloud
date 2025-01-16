//
//  SourceCommitDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/16/25.
//

import SwiftUI

struct SourceCommitDetail: View {
    @ObservedObject var viewModel:ViewModel
    var selectedSourceCommitInfoRepository:SourceCommitInfoRepository
    var body: some View {
        List{
            Section("Repository"){
                HStack{
                    Text("Name")
                    Spacer()
                    Text(selectedSourceCommitInfoRepository.name)
                        .font(.subheadline)
                }
                HStack{
                    Text("Permission")
                    Spacer()
                    Text(selectedSourceCommitInfoRepository.permission ?? "")
                        .font(.subheadline)
                }
                HStack{
                    Text("ActionName")
                    Spacer()
                    Text(selectedSourceCommitInfoRepository.actionName ?? "")
                        .font(.subheadline)
                }
            }
            Section("Branch"){
                HStack{
                    Text("Name")
                    Spacer()
                    Text(selectedSourceCommitInfoRepository.name)
                        .font(.subheadline)
                }
            }
        }
            .navigationTitle(selectedSourceCommitInfoRepository.name)
    }
}
 
#Preview{
    SourceCommitDetail(viewModel: ViewModel(),
                       selectedSourceCommitInfoRepository: SourceCommitInfoRepository(
                        id: 11,
                        name: "name",
                        permission: "permission",
                        actionName: "actionName"
                       ))
}
