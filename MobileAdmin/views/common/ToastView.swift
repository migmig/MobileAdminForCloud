
import SwiftUI
import Logging

struct ToastView: View {
    @ObservedObject var viewModel : ViewModel
    @ObservedObject var toastManager: ToastManager
    //var viewModel : ViewModel = ViewModel()
    @Binding var toastItem:Toast
    @State var isLoading: Bool = false // 로딩중
    @State private var useYn: Bool = false
    @State private var startdt: Date = Date()//getDate(toastItem?.applcBeginDt)
    @State private var enddt:   Date = Date()//getDate(toastItem?.applcEndDt)
    @State private var strCn: String = ""
    
    let logger = Logger(label:"com.migmig.MobileAdmin.ToastView")
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2024, month: 1, day: 1)
        let endComponents = DateComponents(year: 2025, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        return calendar.date(from:startComponents)!
            ...
            calendar.date(from:endComponents)!
    }()
    
    var body: some View {
        ScrollView{
            VStack{
                Section(header: Text("상세 정보").font(.headline)) {
                    HStack {
                        Text("제목").padding()
                        Spacer()
                        TextField("제목", text: Binding(
                            get: {
                                toastItem.noticeHder
                            },
                            set: { newValue in
                                    toastItem.noticeHder = newValue
                            }))
                    }
                    Divider()
                    HStack {
                        Text("내용").padding()
                        Spacer()
                        TextEditor(text:$strCn)
                            .onAppear(){
                                strCn = toastItem.noticeCn.replacingOccurrences(of:"\\n", with: "\n")
                            }
#if os(macOS)
                        .font(.title)
#endif
                        //.border(Color.gray, width: 1)
                    }
#if os(iOS)
                    .frame(height: 150)
#endif
                    
                    Divider()
                    HStack{
                        Text("개시 종료")
                        Spacer()
                        DatePicker("",
                            selection: $toastItem.applcEndDt,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
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
                                        toastItem.useYn = useYn ? "Y" : "N"
                                        await viewModel
                                            .setNoticeVisible(
                                                toastData: toastItem
                                            )
                                        toastItem = await viewModel.fetchToasts()
                                         DispatchQueue.main.async{
                                            useYn = (
                                                toastItem.useYn == "Y"
                                            ) // 업데이트된 상태 반영
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
                            toastItem.noticeCn = strCn.replacingOccurrences(of:"\n", with: "\\n")
                            await viewModel.setToastData(toastData: toastItem)
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
                    toastItem = await viewModel.fetchToasts()
                    useYn = (toastItem.useYn == "Y")
                    isLoading = false;
                  //  startdt  = getDate(toastItem?.applcBeginDt )
                   // enddt    = getDate(toastItem?.applcEndDt)
                }
            }
            .onTapGesture {
#if os(iOS)
                UIApplication.shared.endEditing()// 키보드 내리기
#endif
            }//VStack
        }//ScrollView
    }//body
//    func getDate(_ dateString:String?) -> Date {
//        if(dateString == nil){
//            return Date()
//        }
//        print(dateString)
//        let dateFormatter = DateFormatter()
//
//        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS" // ISO8601 형식
//        return dateFormatter.date(from: dateString!) ?? Date()
//    }
}//struct

