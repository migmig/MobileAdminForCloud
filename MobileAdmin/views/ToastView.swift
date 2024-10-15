 
import SwiftUI

struct ToastView: View {
    @ObservedObject var viewModel : ViewModel 
    @Binding var toastItem:Toast?
    
    @State private var useYn: Bool = false
    var body: some View {
        var toastItem = self.toastItem ?? Toast()
    
        LazyVGrid(columns: [GridItem(.fixed(100)), GridItem(.flexible())], alignment: .leading) {
                Group {
                    Text("개시 시작:")
                        .font(.headline)
                    Text(toastItem.applcBeginDt)
                        .font(.body)
                    
                    Text("개시 종료:")
                        .font(.headline)
                    Text(toastItem.applcEndDt)
                        .font(.body)
                    
                    HStack(alignment: .top){
                        Text("내용:")
                            .font(.headline)
                    }
                    ScrollView(.horizontal){
                        Text(toastItem.noticeCn.replacingOccurrences(of: "\\n", with: "\n"))
                            .font(.body)
                            .padding(.vertical, 4)
                    }
                    Text("표시여부: ")
                        .font(.headline)
                    Toggle(" ", isOn: $useYn)
                         .labelsHidden()
                         .onChange(of: useYn) { newValue in
                             Task{
                                 await viewModel.setNoticeVisible(useYn: newValue ? "Y" : "N")
                                 if let newToast = await viewModel.fetchToasts() {
                                    toastItem = newToast
                                    useYn = (toastItem.useYn == "Y") // 업데이트된 상태 반영
                                 }
                             }
                         }
                
                }
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .onAppear{
            useYn = (toastItem.useYn == "Y")
        }
        #if os(iOS)
        .navigationTitle("Toast")
        #elseif os(macOS)
        .navigationSubtitle("Toast")
        #endif
    }
} 
