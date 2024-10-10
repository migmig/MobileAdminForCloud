//For macOS

import SwiftUI

struct AlternativeContentView: View {
    
    @StateObject var viewModel = ViewModel()
    @State private var toast:Toast?
    @State private var errorItems:[ErrorCloudItem] = []
    @State private var selectedEntry:ErrorCloudItem? = nil
    
    var formatDate:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 날짜 형식을 설정
        return formatter.string(from: Date()) // 포맷된 문자열 반환
    }
    
    var body: some View {
        NavigationSplitView{
            Menu("Actions") {
            Button("Duplicate", action: {})
                Button("Rename", action: {})
                Button("Delete…", action: {})
                Menu("Copy") {
                    Button("Copy", action: {})
                    Button("Copy Formatted", action: {})
                    Button("Copy Library Path", action: {})
                }
            }
            List(errorItems,selection:$selectedEntry){entry in
                NavigationLink(value:entry){
                    ErrorCloudListItem(errorCloudItem: entry)
                }
            }
            .navigationSplitViewColumnWidth(min:200,ideal: 200)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                ToolbarItem{
                    Button{
                        viewModel.fetchErrors(completion:{
                            result in errorItems = result ?? []
                        }, startFrom: formatDate, endTo:  formatDate)
                        viewModel.fetchToasts{ result in
                            toast = result
                        }
                    }label:{
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                    }
                }
            }
        }detail:{
            DetailView(selectedEntry: $selectedEntry)
        }
    }
}
  
#Preview
{
    AlternativeContentView()
}
