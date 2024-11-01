//For iOS
import SwiftUI
struct ErrorListViewForIOS: View {
    @ObservedObject var viewModel:ViewModel
    @ObservedObject var toastManager: ToastManager
    @State private var errorItems:[ErrorCloudItem] = []
    @State private var searchText = ""
    @State private var isSearchBarVisible:Bool = true
    @State private var isLoading: Bool = false
    //    let errorItems:[ErrorCloudItem]
    
    var formatDate:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 날짜 형식을 설정
        return formatter.string(from: Date()) // 포맷된 문자열 반환
    }
    
    var filteredErrorItems: [ErrorCloudItem] {
        if searchText.isEmpty {
            return errorItems
        }else{
            return errorItems.filter{$0.description?.localizedCaseInsensitiveContains(searchText) == true}
        }
    }
    
    var body: some View {
        NavigationStack{
            
            VStack() {
                if isLoading{
                    ProgressView(" ").progressViewStyle(CircularProgressViewStyle())
                }
                // 검색창 추가
                if isSearchBarVisible {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray) // 아이콘 색상
                            .padding(.leading, 10) // 아이콘 왼쪽 패딩
                        
                        TextField("검색어 입력...", text: $searchText)
                            .padding(10)
                            .cornerRadius(10) // 모서리 둥글게
                            .font(.system(size: 16)) // 폰트 크기
                        Text("\(filteredErrorItems.count)개의 오류")
                    }
                    .padding(.horizontal) // 전체 HStack의 패딩
                }
                List(filteredErrorItems){entry in
                    NavigationLink(value:entry){
                        ErrorCloudListItem(errorCloudItem: entry)
                    }
                    
                }
                .navigationTitle("ErrorList")
                .navigationDestination(for: ErrorCloudItem.self){entry in
                    ErrorCloudItemView(errorCloudItem: entry,
                                       toastManager: toastManager)
                }
            }
        }
        .onAppear(){
            Task{
                isLoading = true;
                await errorItems = viewModel.fetchErrors(startFrom: formatDate, endTo:  formatDate) ?? []
                isLoading = false;
            }
        }
        .refreshable {
            Task{
                isLoading = true;
                await errorItems = viewModel.fetchErrors(startFrom: formatDate, endTo:  formatDate) ?? []
                isLoading = false;
            }
        } 
    }
    
}

#Preview{
    ErrorListViewForIOS(viewModel: .init(),toastManager: .init())
}
