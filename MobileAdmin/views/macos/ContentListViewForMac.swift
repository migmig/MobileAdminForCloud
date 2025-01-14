import SwiftUI

struct ContentListViewForMac: View {
    @ObservedObject var viewModel:ViewModel = ViewModel()
    @Binding var selectedSlidebarItem:SlidebarItem?
    @Binding var toast:Toast
    @Binding var goodsinfos:[Goodsinfo]
    @Binding var selectedGoods:Goodsinfo?
    @Binding var selectedErrorItem:ErrorCloudItem?
    @Binding var errorItems:[ErrorCloudItem]
    @Binding var edcCrseCl:[EdcCrseCl]
    @Binding var selectedEdcCrseCl:EdcCrseCl?
    @Binding var groupCodes:[CmmnGroupCodeItem]?
    @Binding var selectedGroupCode:CmmnGroupCodeItem?
    @Binding var closeDeptList:[Detail1]
    @Binding var selectedCloseDept:Detail1?
    @Binding var selectedSourceBuildProject:SourceBuildProject?
    @State private var isLoading:Bool = false
    @State private var searchText = ""
    
    
    var formatDate:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 날짜 형식을 설정
        return formatter.string(from: Date()) // 포맷된 문자열 반환
    }
      
    
    var body: some View {
        Group {
            if let selectedItem = selectedSlidebarItem {
                makeSidebar(for: selectedItem)
            } else {
                Text("선택된 항목이 없습니다.")
            }
        }
    }
    
    @ViewBuilder
    private func makeSidebar(for item: SlidebarItem) -> some View {
        switch item {
        case .errerlist:
            ErrorSidebar(errorItems: $errorItems, selectedErrorItem: $selectedErrorItem)
            
        case .toast:
            List {
                if isLoading {
                    ProgressView("로딩 중...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                NavigationLink(value: toast) {
                    Text(toast.noticeHder)
                }
            }
            
        case .goodsInfo:
            GoodsSidebar(goodsItems: $goodsinfos, selectedGoods: $selectedGoods)
            
        case .gcpClsList:
            EdcClsSidebar(viewModel: viewModel, edcCrseCl: $edcCrseCl, selectedEdcCrseCl: $selectedEdcCrseCl)
            
        case .codeList:
            GroupCodesSidebar(viewModel: viewModel, groupCodes: $groupCodes, selectedGroupCode: $selectedGroupCode)
            
        case .closeDeptList:
            CloseDeptSidebar(viewModel: viewModel, list: $closeDeptList, selectedCloseDept: $selectedCloseDept)
            
        case .sourceBuild:
            SourceBuildSidebar(viewModel: viewModel, selectedSourceBuildProject: $selectedSourceBuildProject)
        default:
            Text("알 수 없는 항목입니다.")
        }
    }
}

#Preview{
    ContentListViewForMac(
        selectedSlidebarItem: .constant(SlidebarItem.sourceBuild),
        toast: .constant(Toast(applcBeginDt: Date(),
                               applcEndDt: Date(),
                               noticeHder: "제목",
                               noticeSj: "제목",
                               noticeCn: "내용\n\n 내용  내용\n\n 내용내용\n\n 내용내용\n\n 내용",
                               useYn: "N")),
        goodsinfos: .constant([]),
        selectedGoods: .constant(nil),
        selectedErrorItem: .constant(nil),
        errorItems: .constant([]),
        edcCrseCl: .constant([EdcCrseCl(
            "강의제목2",
            "강의내용 길게길게길게 "
        ),EdcCrseCl(
            "강의제목1",
            "강의내용 길게길게길게 "
        )]),
        selectedEdcCrseCl: .constant(EdcCrseCl(
            "강의제목",
            "강의내용 길게길게길게 "
        )),
        groupCodes:.constant([CmmnGroupCodeItem(
            cmmnGroupCode: "그룹코드",
            cmmnGroupCodeNm: "그룹코드명",
            groupEstbs1Value: "그룹코드설명",
            groupEstbs2Value: "사용여부",
            groupEstbs3Value: "등록자",
            groupEstbs4Value: "등록일",
            groupEstbs5Value: "수정자",
            groupEstbs6Value: "수정일",
            groupEstbs7Value: "수정일",
            useAt:"Y"
        )])
        ,
        selectedGroupCode: .constant(CmmnGroupCodeItem(
            cmmnGroupCode: "그룹코드",
            cmmnGroupCodeNm: "그룹코드명",
            groupEstbs1Value: "그룹코드설명",
            groupEstbs2Value: "사용여부",
            groupEstbs3Value: "등록자",
            groupEstbs4Value: "등록일",
            groupEstbs5Value: "수정자",
            groupEstbs6Value: "수정일",
            groupEstbs7Value: "수정일",
            useAt:"Y"
        ))
        , closeDeptList:.constant([
                  Detail1(
                                closeempno: "",
                                rmk: "개시",
                                deptprtnm: "수원1",
                                closegb: "1",
                                closetime: "",
                                opentime: "",
                                deptcd: "101"
                    )
                  ,Detail1(
                    closeempno: "",
                    rmk: "개시1",
                    deptprtnm: "수원2",
                    closegb: "2",
                    closetime: "",
                    opentime: "",
                    deptcd: "102"
                    )
                  ,Detail1(
                    closeempno: "",
                    rmk: "개시",
                    deptprtnm: "수원3",
                    closegb: "0",
                    closetime: "",
                    opentime: "",
                    deptcd: "103"
                    )
                  ,Detail1(
                    closeempno: "",
                    rmk: "개시",
                    deptprtnm: "수원4",
                    closegb: "",
                    closetime: "",
                    opentime: "",
                    deptcd: "104"
                    )
                  ,Detail1(
                    closeempno: "",
                    rmk: "개시",
                    deptprtnm: "수원5",
                    closegb: "",
                    closetime: "",
                    opentime: "",
                    deptcd: "105"
                    )
                  ,Detail1(
                    closeempno: "",
                    rmk: "개시",
                    deptprtnm: "수원6",
                    closegb: "",
                    closetime: "",
                    opentime: "",
                    deptcd: "106"
                    )
        ])
        ,
        selectedCloseDept:
                .constant(
                    Detail1(
                        closeempno: "",
                        rmk: "개시",
                        deptprtnm: "수원",
                        closegb: "",
                        closetime: "",
                        opentime: "",
                        deptcd: "100"
                    )
                ), selectedSourceBuildProject: .constant(nil)
        
    )
}
 
