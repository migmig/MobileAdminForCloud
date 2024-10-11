 
import SwiftUI

struct ToastView: View {
    //let viewModel : ViewModel
    @Binding var toastItem:Toast?
    var body: some View {
        let toastItem = self.toastItem ?? Toast()
        LazyVGrid(columns: [GridItem(.fixed(100)), GridItem(.flexible())], alignment: .leading) {
                Group {
                    Text("개시 시작:")
                    Text(toastItem.applcBeginDt) 
                    
                    Text("개시 종료:")
                    Text(toastItem.applcEndDt)
                    
                    HStack(alignment: .top){
                        Text("내용:")
                    }
                    ScrollView(.horizontal){
                        Text(toastItem.noticeCn.replacingOccurrences(of: "\\n", with: "\n"))
                            .padding(.vertical, 4)
                    }
                    Text("표시여부: ")
                    Toggle(" ", isOn: Binding(
                        get: { toastItem.useYn == "Y" },
                        set: { newValue in
//                            toastItem.useYn = newValue ? "Y" : "N"
                            print(toastItem)
                        }
                    )).labelsHidden()
                
                }
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
//        .onAppear(){
//            Task{
//                await toastItem = viewModel.fetchToasts() ?? Toast()
//            }
//        }
        #if os(iOS)
        .navigationTitle("Toast")
        #elseif os(macOS)
        .navigationSubtitle("Toast")
        #endif
    }
} 
