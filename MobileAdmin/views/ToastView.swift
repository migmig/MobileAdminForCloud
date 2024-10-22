
import SwiftUI
import Logging

struct ToastView: View {
    @ObservedObject var viewModel : ViewModel
    @ObservedObject var toastManager: ToastManager
    //var viewModel : ViewModel = ViewModel()
    @Binding var toastItem:Toast?
   
    @State private var useYn: Bool = false
   
    let logger = Logger(label:"com.migmig.MobileAdmin.ToastView")
   
    var body: some View {
       
       VStack{
           Section(header: Text("상세 정보").font(.headline)) {
               HStack {
                   Text("제목").padding()
                   Spacer()
                   TextEditor(text: Binding(
                    get: {
                        toastItem?.noticeHder ?? ""
                    },
                    set: { newValue in
                        if toastItem != nil {
                            toastItem?.noticeHder = newValue
                        }
                    }))
                   .frame(height: 30 )
                  // .border(Color.gray, width: 1)
               }
               Divider()
               HStack {
                   Text("내용").padding()
                   Spacer()
                   TextEditor(text: Binding(
                    get: {
                        toastItem?.noticeCn ?? ""
                    },
                    set: { newValue in
                        if toastItem != nil {
                            toastItem?.noticeCn = newValue
                        }
                    }))
                   //.border(Color.gray, width: 1)
               }
               Divider()
               InfoRow(title: "개시 시작", value: Util.formatDateTime(from: toastItem?.applcBeginDt))
               InfoRow(title: "개시 종료", value: Util.formatDateTime(from: toastItem?.applcEndDt))
               Divider()
               HStack {
                   Text("표시여부: ")
                       .font(.headline)
                   Spacer()
                   Toggle(" ", isOn: $useYn)
                      .labelsHidden()
                      .onChange(of: useYn) { newValue in
                          Task{
                              toastItem?.useYn = newValue ? "Y" : "N"
                              await viewModel.setNoticeVisible(toastData: toastItem!)
                              if let newToast = await viewModel.fetchToasts() {
                                  toastItem = newToast
                                  useYn = (toastItem?.useYn == "Y") // 업데이트된 상태 반영
                              }
                          }
                      }
               }
//       //var toastItem = self.toastItem ?? Toast(applcBeginDt: "", applcEndDt: "", noticeHder: "", noticeSj: "", noticeCn: "", useYn: "")
//       VStack{
//           Text("Toast")
//               .font(.title)
//               .fontWeight(.bold)
//           LazyVGrid(columns: [GridItem(.fixed(100)), GridItem(.flexible())], alignment: .leading) {
//               Group {
//
//                   Text("개시 시작:")
//                       .font(.headline)
//                   Text(toastItem?.applcBeginDt ?? "")
//                       .font(.body)
//
//                   Text("개시 종료:")
//                       .font(.headline)
//                   Text(toastItem?.applcEndDt ?? "")
//                       .font(.body)
//
//
//                   Text("제목")
//                       .font(.headline)
//
//                   TextEditor(text: Binding(
//                        get: {
//                            toastItem?.noticeHder ?? ""
//                       },
//                        set: { newValue in
//                            if toastItem != nil {
//                                toastItem?.noticeHder = newValue
//                            }
//                        }))
//                   .border(Color.gray, width: 1)
//
//                   HStack(alignment: .top){
//                       Text("내용:")
//                           .font(.headline)
//                   }
//                   //ScrollView(.horizontal){
//                   TextEditor(text: Binding(
//                        get: {
//                           toastItem?.noticeCn ?? ""
//                       },
//                        set: { newValue in
//                            if toastItem != nil {
//                                toastItem?.noticeCn = newValue
//                            }
//                        }))
//                   .border(Color.gray, width: 1)
//
//                   Text("표시여부: ")
//                       .font(.headline)
//                   Toggle(" ", isOn: $useYn)
//                       .labelsHidden()
//                       .onChange(of: useYn) { newValue in
//                           Task{
//                               toastItem?.useYn = newValue ? "Y" : "N"
//                               await viewModel.setNoticeVisible(toastData: toastItem!)
//                               if let newToast = await viewModel.fetchToasts() {
//                                   toastItem = newToast
//                                   useYn = (toastItem?.useYn == "Y") // 업데이트된 상태 반영
//                               }
//                           }
//                       }
//                   Text("")
                   Button(action: {
                       #if os(iOS)
                       UIImpactFeedbackGenerator(style: .medium).impactOccurred() // 피드백 발생 진동
                       #endif
                               // 저장 로직
                                 Task{
                                      await viewModel.setToastData(toastData: toastItem!)
                                     logger.info("저장완료")
                                     toastManager.showToast(message:"저장되었습니다.")
                                 }
                           }) {
                               Label("저장", systemImage: "square.and.arrow.down")
                                   .font(.system(size: 16, weight: .semibold))
                                   .padding(.vertical, 8)
                                   .padding(.horizontal, 12)
                                   .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                                   .foregroundColor(.white)
                           }
                           .buttonStyle(PlainButtonStyle()) // macOS에서 기본 버튼 스타일 제거
                           .shadow(radius: 2, x: 0, y: 2) // 살짝의 그림자 효과
                   
                  
                   
               }
               .padding(.vertical, 4)
           }
           .padding()
           .onAppear{
               Task{
                   toastItem = await viewModel.fetchToasts() ?? toastItem
                   useYn = (toastItem?.useYn == "Y")
               }
           }
           .onTapGesture {
               #if os(iOS)
               UIApplication.shared.endEditing()
               #endif
           }
        }
//       .padding()
//       .frame(maxWidth: .infinity, alignment: .leading)
//       #if os(iOS)
//       .navigationTitle("Toast")
//       #elseif os(macOS)
//       .navigationSubtitle("Toast")
//       #endif
}
//
//struct ToastView_Previews: PreviewProvider {
//    static var previews: some View {
//        // 임시 Toast 데이터를 생성합니다.
//        let exampleToast = Toast(applcBeginDt: "2024-01-01", applcEndDt: "2024-12-31"
//                                 , noticeHder: "공지사항 제목입니다.", noticeSj: "Y"
//                                 , noticeCn: "안녕하세요.\n\n[EasyOne] 긴급 반영 안내10/04\n\n대환 신청 시 일부 상황에서 흰 페이지만 뜨는 현상이 있어 \n프로그램 수정 후 반영 진행합니다. 시스템 안정적인 운영을 위해 지속적으로 개선하도록 하겠습니다.\n\n감사합니다."
//                                 , useYn: "Y")
//
//        // 임시 ViewModel 객체를 생성하여 프리뷰에 전달합니다.
//        let exampleViewModel = ViewModel()
//
//        ToastView(viewModel: exampleViewModel, toastItem: .constant(exampleToast))
//    }
//}
