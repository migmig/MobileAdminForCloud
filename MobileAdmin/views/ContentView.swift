//For iOS


import SwiftUI


struct ContentView: View {
    let viewModel:ViewModel
    @State private var errorItems:[ErrorCloudItem] = []
//    let errorItems:[ErrorCloudItem]
    
    var formatDate:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 날짜 형식을 설정
        return formatter.string(from: Date()) // 포맷된 문자열 반환
    }
    
    var body: some View {
        NavigationStack{
            List(errorItems){entry in
                NavigationLink(value:entry){
                    ErrorCloudListItem(errorCloudItem: entry)
                }
                .navigationTitle("ErrorList")
                
            }
            .navigationDestination(for: ErrorCloudItem.self){entry in
                ErrorCloudItemView(errorCloudItem: entry)
            }
        }
        .onAppear(){
            Task{
                print("OnAppear")
                await errorItems = viewModel.fetchErrors(startFrom: formatDate, endTo:  formatDate) ?? []
            }
        }
        .refreshable {
            Task{
                print("OnRefresh")
                await errorItems = viewModel.fetchErrors(startFrom: formatDate, endTo:  formatDate) ?? []
            }
        }
        
//        VStack(spacing: 3.0) {
//             
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//          
//            Text("\(toast?.noticeCn ?? "Hello, world!")")
//            
//        }.padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/).onTapGesture {
//            viewModel.fetchErrors(completion:{result in errorItems = result ?? []}, startFrom: "2024-10-08", endTo:  "2024-10-08")
//            toast = Toast()
//            viewModel.fetchToasts{ result in
//               
//                toast = result
//            }
    }
    
} 
