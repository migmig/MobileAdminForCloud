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
            return "Source Commit"
        case .sourceBuild:
            return "Source Build"
        case .sourceDeploy:
            return "Source Deploy"
        case .sourcePipeline:
            return "Source Pipeline"
        case .collection(let title):
            return title
        }
    }
    var img: String{
        switch self{
        case .errerlist:
            return "cloud"
        case .toast:
            return "bell"
        case .goodsInfo:
            return "cart"
        case .gcpClsList:
            return "list.bullet.rectangle"
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
}


struct SlidebarViewForMac: View {
    @Binding var selection: SlidebarItem?
    var body: some View {
        List(selection:$selection){
            Section(header:Text("클라우드")){
                ForEach(SlidebarItem.CloudTools, id: \.self){ item in
                    NavigationLink(value:item){
                        //Text(item.title)
                        Label(" [ \(item.title) ] ", systemImage: item.img)
                            .font(.title2)
                    }
                }
            }
            Section(header:Text("내부시스템")){
                ForEach(SlidebarItem.InnerSystems, id: \.self){ item in
                    NavigationLink(value:item){
                        //Text(item.title)
                        Label(" [ \(item.title) ] ", systemImage: item.img)
                            .font(.title2)
                    }
                }
            }
            Section(header:Text("개발도구")){
                ForEach(SlidebarItem.DeveloperTools, id: \.self){ item in
                    NavigationLink(value:item){
                        //Text(item.title)
                        Label(" [ \(item.title) ] ", systemImage: item.img)
                            .font(.title2)
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
        SlidebarViewForMac(selection: $selected)
    }
}
