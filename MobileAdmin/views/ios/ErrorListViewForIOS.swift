//For iOS
import SwiftUI
struct ErrorListViewForIOS: View {
    @ObservedObject var viewModel:ViewModel
    @State private var searchText = ""
    @State private var isSearchBarVisible:Bool = true
    @State private var isLoading: Bool = false
    @State private var dateFrom:Date = Date()
    @State private var dateTo:Date = Date()
    
    
    var filteredErrorItems: [ErrorCloudItem] {
        if searchText.isEmpty {
            return viewModel.errorItems
        }else{
            return viewModel.errorItems.filter{$0.description?.localizedCaseInsensitiveContains(searchText) == true}
        }
    }
    
    var body: some View {
       // NavigationStack{
            
            VStack() {
                List{
                    Section{
                        SearchArea(dateFrom: $dateFrom,
                                   dateTo: $dateTo,
                                   isLoading: $isLoading,
                                   clearAction:{
                            searchText = ""
                        }){
                            viewModel.errorItems = await viewModel.fetchErrors(startFrom: dateFrom, endTo:  dateTo) ?? []
                        }//.padding()
                        // 검색창 추가
                        if isSearchBarVisible {
                            HStack(alignment:.center) { 
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
                    .searchable(text: $searchText , placement: .automatic)
                    ForEach(filteredErrorItems,id:\.id){entry in
                        NavigationLink(destination: ErrorCloudItemView(errorCloudItem: entry)){
                            ErrorCloudListItem(errorCloudItem: entry)
                        }
                        
                    }
                }
                .navigationTitle("오류 조회")
            }
        //}
        .onAppear(){
            Task{
                isLoading = true;
                await viewModel.errorItems = viewModel.fetchErrors(startFrom: dateFrom,
                                                         endTo:  dateTo) ?? []
                isLoading = false;
            }
        }
        .refreshable {
            Task{
                isLoading = true;
                await viewModel.errorItems = viewModel.fetchErrors(startFrom: dateFrom,
                                                         endTo:  dateTo) ?? []
                isLoading = false;
            }
        }
    }
    
}

#Preview{
    ErrorListViewForIOS(viewModel: .init() )
}
