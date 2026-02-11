//
//  EdcEducationCrseInfoDetail.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/11/24.
//

import SwiftUI
import AVKit

struct EdcEducationCrseInfoDetail: View {
    @ObservedObject var viewModel : ViewModel
    @State private var crseTmeList:[GcpEdcCrseTmeList] = []
    @StateObject private var videoViewModel = VideoPlayerViewModel()
//    private let player: AVPlayer
    var edcCrseId:Int
    var body: some View {
        VStack{
            List{
                ForEach(crseTmeList, id: \.self){ item in
                    InfoRowCustom(title:item.edcTitleInfo ?? ""){
                        HStack{
                            VideoPlayerView(
                                videoURL:URL(string:  Util.urlEncode(item.edcVidoUrl))!
                            )
                            .frame(
                                width: 300,
                                height: 300
                            )
                        }
                    }
                }
            }
        }
        .onAppear(){
            Task{
                let resp:EdcCrseResponse  = await viewModel.fetchClsInfo(
                    edcCrseId: edcCrseId
                )
                
                crseTmeList = resp.gcpEdcCrseClAndTimeVO.gcpEdcCrseTmeList
                crseTmeList.forEach{ item in
                    print(URL(string:  Util.urlEncode(item.edcVidoUrl))!)
                }
            }
        }
    }
}
 
