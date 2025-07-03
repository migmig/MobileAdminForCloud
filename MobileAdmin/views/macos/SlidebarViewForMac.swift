//
//  SlidebarView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/11/24.
//

import SwiftUI

enum SlidebarItem: Hashable,CaseIterable{
    static var allCases: [SlidebarItem]{
        return [
                .errerlist,
                .toast,
                .goodsInfo,
                .gcpClsList,
                .codeList,
                .closeDeptList,
                .sourceBuild
        ]
    }
    static var CloudTools: [SlidebarItem]{
        return [
            .errerlist,
            .toast,
            .gcpClsList,
            .codeList,
        ]
    }
    
    static var InnerSystems: [SlidebarItem]{
        return [
            .goodsInfo,
            .closeDeptList
        ]
    }
    
    static var DeveloperTools: [SlidebarItem]{
        return [
            .sourceCommit,
                .sourceBuild,
                .sourceDeploy,
                .sourcePipeline
        ]
    }
    // Hashable 프로토콜을 준수하도록 변경

    case errerlist,
         toast,
         goodsInfo,
         gcpClsList,
         codeList,
         closeDeptList,
         sourceCommit,
         sourceBuild,
         sourceDeploy,
         sourcePipeline
         
    
    case collection(String)
    
    var title: String{
        switch self{
        case .errerlist:
            return "오류 조회"
        case .toast:
            return "토스트관리"
        case .goodsInfo:
            return "상품 이력"
        case .gcpClsList:
            return "교육 조회"
        case .codeList:
            return "코드목록"
        case .closeDeptList:
            return "개시여부"
        case .sourceCommit:
            return "Src Commit"
        case .sourceBuild:
            return "Src Build"
        case .sourceDeploy:
            return "Src Deploy"
        case .sourcePipeline:
            return "Src Pipeline"
        case .collection(let title):
            return title
        }
    }
    var img: String{
        switch self{
        case .errerlist:
            return "exclamationmark.icloud"
        case .toast:
            return "bell.badge"
        case .goodsInfo:
            return "cart"
        case .gcpClsList:
            return "graduationcap"
        case .codeList:
            return "doc.text"
        case .closeDeptList:
            return "square.and.pencil"
        case .sourceCommit:
            return "arrow.up.arrow.down.circle"
        case .sourceDeploy:
            return "arrow.up.circle"
        case .sourcePipeline:
            return "rectangle.connected.to.line.below"
        case .sourceBuild:
            return "gearshape.2"
        case .collection(let title):
            return title
        }
    }
    static let groups: [(String, [SlidebarItem])] = [
           ("클라우드", [.errerlist
                     //, .toast
                     //, .gcpClsList
                     , .codeList]),
           ("내부시스템", [.goodsInfo, .closeDeptList]),
           ("개발도구", [
                     //.sourceCommit,
               .sourceBuild, .sourceDeploy, .sourcePipeline])
       ]
}


struct SlidebarViewForMac: View {
    @Binding var selection: SlidebarItem?
    var body: some View {
        List(selection:$selection){
            ForEach(SlidebarItem.groups, id: \.0) { (header, items) in
               Section(header: Text(header)) {
                   ForEach(items, id: \.self) { item in
                       NavigationLink(value: item) {
                           Label(" [ \(item.title) ] ", systemImage: item.img)
                               .font(.title2)
                       }
                   }
               }
           }
        }
        .onChange(of: selection){old, newValue in
            print("Selected: \(newValue?.title ?? "nil")")
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
        NavigationStack{
            SlidebarViewForMac(selection: $selected)
        }
    }
}
