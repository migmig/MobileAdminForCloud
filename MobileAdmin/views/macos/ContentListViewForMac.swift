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
    @State private var isLoading:Bool = false
    @State private var searchText = ""
    
    
    var formatDate:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 날짜 형식을 설정
        return formatter.string(from: Date()) // 포맷된 문자열 반환
    }
      
    
    var body: some View {
        
        if(selectedSlidebarItem == SlidebarItem.errerlist){
            ErrorSidebar(errorItems:$errorItems,
                         selectedErrorItem :$selectedErrorItem)
        }else if(selectedSlidebarItem == SlidebarItem.toast){
            List{
                if isLoading {
                    ProgressView(" ")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                NavigationLink(value:toast){
                    Text(toast.noticeHder )
                }
            }
        }else if(selectedSlidebarItem == SlidebarItem.goodsInfo){
            GoodsSidebar(goodsItems: $goodsinfos,
                         selectedGoods: $selectedGoods)
        }else if(selectedSlidebarItem == SlidebarItem.gcpClsList){
            EdcClsSidebar(
                viewModel: viewModel,
                edcCrseCl: $edcCrseCl,
                selectedEdcCrseCl: $selectedEdcCrseCl
            )
        }else if(selectedSlidebarItem == SlidebarItem.codeList){
            GroupCodesSidebar(viewModel: viewModel,
                              groupCodes: $groupCodes,
                              selectedGroupCode: $selectedGroupCode)
        }else{
            Text(" ")
        }
    }
}

#Preview{
    ContentListViewForMac(
        selectedSlidebarItem: .constant(SlidebarItem.codeList),
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
        ,selectedGroupCode: .constant(CmmnGroupCodeItem(
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
    )
}
 
