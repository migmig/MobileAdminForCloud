
import SwiftUI
import Logging

struct ToastView: View {
    @ObservedObject var viewModel : ViewModel
    @ObservedObject var toastManager: ToastManager
    //var viewModel : ViewModel = ViewModel()
    @Binding var toastItem:Toast?
    @State var isLoading: Bool = false // 로딩중 
    @State private var useYn: Bool = false
    
    let logger = Logger(label:"com.migmig.MobileAdmin.ToastView")
    
    var body: some View {
        ScrollView{
            VStack{
                Section(header: Text("상세 정보").font(.headline)) {
                    HStack {
                        Text("제목").padding()
                        Spacer()
                        TextField("제목", text: Binding(
                            get: {
                                toastItem?.noticeHder ?? ""
                            },
                            set: { newValue in
                                if toastItem != nil {
                                    toastItem?.noticeHder = newValue
                                }
                            }))
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
#if os(macOS)
                        .font(.title)
#endif
                        //.border(Color.gray, width: 1)
                    }
#if os(iOS)
                    .frame(height: 150)
#endif
                    Divider()
                    InfoRow(title: "개시 시작", value: Util.formatDateTime(toastItem?.applcBeginDt))
                    InfoRow(title: "개시 종료", value: Util.formatDateTime(toastItem?.applcEndDt))
                    Divider()
                    HStack {
                        Text("표시여부: ")
                            .font(.headline)
                        Spacer()
                        if #available(iOS 17.0, *) {
                            Toggle(" ", isOn: $useYn)
                                .labelsHidden()
                                .onChange(of: useYn) {
                                    Task{
                                        toastItem?.useYn = useYn ? "Y" : "N"
                                        await viewModel
                                            .setNoticeVisible(
                                                toastData: toastItem!
                                            )
                                        if let newToast = await viewModel.fetchToasts() {
                                            DispatchQueue.main.async{
                                                toastItem = newToast
                                                useYn = (
                                                    toastItem?.useYn == "Y"
                                                ) // 업데이트된 상태 반영
                                            }
                                        }
                                    }
                                }
                        } else {
                            // Fallback on earlier versions
                        }
                    }
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
#if os(macOS)
                    .buttonStyle(PlainButtonStyle()) // macOS에서 기본 버튼 스타일 제거
#endif
                    .shadow(radius: 2, x: 0, y: 2) // 살짝의 그림자 효과
                                       
                    
                }
                .padding(.vertical, 4)
            }
            .padding()
            .onAppear{
                Task{
                    isLoading = true;
                    toastItem = await viewModel.fetchToasts() ?? toastItem
                    useYn = (toastItem?.useYn == "Y")
                    isLoading = false;
                }
            }
            .onTapGesture {
#if os(iOS)
                UIApplication.shared.endEditing()// 키보드 내리기
#endif
            }//VStack
        }//ScrollView
    }//body
}//struct

