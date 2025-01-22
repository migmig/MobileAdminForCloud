//
//  SourceBuildListViewIOS.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/14/25.
//

import SwiftUI

struct SourceCommitListView: View {
    @ObservedObject var viewModel:ViewModel
    @Binding var selectedCommit:SourceCommitInfoRepository?
    @State var searchText:String = ""
    var body: some View {
           // VStack{
        List(selection: $selectedCommit){
            ForEach(viewModel.sourceCommitInfoRepository, id:\.id){ item in
                #if os(iOS)
                NavigationLink(destination:{
                    SourceCommitDetail(viewModel:viewModel,
                                       selectedSourceCommit: item)
                }){
                    HStack{
                        Image(systemName: SlidebarItem.sourceCommit.img)
                            .foregroundColor(.blue)
                        Text(item.name)
                    }
                }
                #endif
                #if os(macOS)
                NavigationLink(value: item){
                    HStack{
                        Image(systemName: SlidebarItem.sourceCommit.img)
                            .foregroundColor(.blue)
                        Text(item.name)
                    }
                }
                #endif
            }
#if os(macOS)
.font(.title2)
#endif
                }
                 
            //}
            .navigationTitle("소스커밋목록")
//            .onChange(of: selectedSourceCommitInfoRepository?.id) {_, newValue in
//            }
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
    NavigationStack{
        SourceCommitListView(viewModel: ViewModel(), selectedCommit: .constant(nil))
    }
}
