//
//  SlidebarView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/11/24.
//

import SwiftUI

enum SlidebarItem: Hashable,CaseIterable{
    static var allCases: [SlidebarItem]{
        return [.errerlist,.toast,.goodsInfo]
    }
    // Hashable 프로토콜을 준수하도록 변경

    case errerlist,toast,goodsInfo
    case collection(String)
    
    var title: String{
        switch self{
        case .errerlist:
            return "에러이력"
        case .toast:
            return "토스트관리"
        case .goodsInfo:
            return "상품이력"
        case .collection(let title):
            return title
        }
    }
    var img: String{
        switch self{
        case .errerlist:
            return "checkmark.message"
        case .toast:
            return "ellipsis.message"
        case .goodsInfo:
            return "info.bubble"
        case .collection(let title):
            return title
        }
    }
}


struct SlidebarViewForMac: View {
    @Binding var selection: SlidebarItem?
    var body: some View {
        List(selection:$selection){
            Section(header:Text("화면목록")){
                ForEach(SlidebarItem.allCases, id: \.self){ item in
                    NavigationLink(value:item){
                        //Text(item.title)
                        Label(item.title, systemImage: item.img)
                            .font(.title2)
                    }
                }
            }
            
        }
    }
}

struct SlidebarView_Previews: PreviewProvider {
    static var previews: some View {
        // 예시용 PreviewProvider 생성
        StatePreview()
    }
}

struct StatePreview: View {
    @State private var selected: SlidebarItem? = nil

    var body: some View {
        SlidebarViewForMac(selection: $selected)
    }
}
