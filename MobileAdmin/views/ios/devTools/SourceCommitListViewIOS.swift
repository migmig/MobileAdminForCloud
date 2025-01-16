//
//  SourceBuildListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/14/25.
//

import SwiftUI

struct SourceCommitListViewIOS: View {
    @ObservedObject var viewModel:ViewModel
   // @State var selectedSourceCommitInfoRepository:SourceCommitInfoRepository?
    @State var searchText:String = ""
    var body: some View {
            VStack{
                List{
                    ForEach(viewModel.sourceCommitInfoRepository, id:\.id){ item in
                        NavigationLink(destination:{
                            SourceCommitDetail(viewModel:viewModel,
                                               selectedSourceCommitInfoRepository: item)
                        }){
                            HStack{
                                Image(systemName: SlidebarItem.sourceCommit.img)
                                    .foregroundColor(.blue)
                                Text(item.name)
                            }
                        }
                    }
                }
                 
            }
            .navigationTitle("소스커밋목록")
            .onAppear(){
                if viewModel.sourceCommitInfoRepository.isEmpty {
                    Task{
                        let repoInfo = await viewModel.fetchSourceCommitList()
                        
                        await MainActor.run{
                            viewModel.sourceCommitInfoRepository = repoInfo.result.repository
                                .sorted(by: {$0.id  < $1.id  })
                        }
                         
                    }
                }
            }
        //}
    }
}

#Preview{
    SourceCommitListViewIOS(viewModel: ViewModel())
}
