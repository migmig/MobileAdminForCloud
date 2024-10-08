
import SwiftUI


struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    @State private var toast:Toast?
    @State private var errorItems:[ErrorCloudItem] = []
//    let errorItems:[ErrorCloudItem]
    
    var body: some View {
        NavigationStack{
            List(errorItems){entry in
                NavigationLink(value:entry){
                    ErrorCloudListItem(errorCloudItem: entry)
                }
            }
            .navigationDestination(for: ErrorCloudItem.self){entry in
                ErrorCloudItemView(errorCloudItem: entry)
            }
        }
        .onAppear(){
            viewModel.fetchErrors(completion:{result in errorItems = result ?? []}, startFrom: "2024-10-08", endTo:  "2024-10-08")
            viewModel.fetchToasts{ result in
                toast = result
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

#Preview {
    ContentView()
}
 
