//For iOS
import SwiftUI
struct ErrorListViewForIOS: View {
    @ObservedObject var viewModel:ViewModel
    @ObservedObject var toastManager: ToastManager
    @State private var errorItems:[ErrorCloudItem] = []
    @State private var searchText = ""
    @State private var isSearchBarVisible:Bool = true
    @State private var isLoading: Bool = false
    @State private var dateFrom:Date = Date()
    @State private var dateTo:Date = Date()
    
    
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
                List{
                    Section{
                        SearchArea(dateFrom: $dateFrom,
                                   dateTo: $dateTo,
                                   isLoading: $isLoading,
                                   clearAction:{
                            searchText = ""
                        }){
                            errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo:  dateTo) ?? []
                        }//.padding()
                        // 검색창 추가
                        if isSearchBarVisible {
                            HStack(alignment:.center) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray) // 아이콘 색상
                                    .padding(.leading, 10) // 아이콘 왼쪽 패딩
                                
                                TextField("검색어 입력...", text: $searchText)
                                    .padding(10)
                                    .cornerRadius(10) // 모서리 둥글게
                                    .font(.system(size: 16)) // 폰트 크기
                                if isLoading{
                                    VStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .frame(maxHeight: .infinity)
                                    }
                                }
                                Text("\(filteredErrorItems.count)개의 오류")
                            }
                            .frame(maxHeight:40)
                            .padding(.horizontal) // 전체 HStack의 패딩
                            
                        }
                    }
                    ForEach(filteredErrorItems,id:\.id){entry in
                        NavigationLink(value:entry){
                            ErrorCloudListItem(errorCloudItem: entry)
                        }
                        
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
                await errorItems = viewModel.fetchErrors(startFrom: dateFrom,
                                                         endTo:  dateTo) ?? []
                isLoading = false;
            }
        }
        .refreshable {
            Task{
                isLoading = true;
                await errorItems = viewModel.fetchErrors(startFrom: dateFrom,
                                                         endTo:  dateTo) ?? []
                isLoading = false;
            }
        }
    }
    
}

#Preview{
    ErrorListViewForIOS(viewModel: .init(),toastManager: .init())
}
