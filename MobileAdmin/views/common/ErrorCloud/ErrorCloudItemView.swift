import SwiftUI
#if os(macOS)
import AppKit
#endif
struct ErrorCloudItemView: View {
    @ObservedObject var viewModel: ViewModel
    var errorCloudItem: ErrorCloudItem
    @State private var isSheetPresented: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) { // 카드 간 간격
                
                // MARK: - 상세 정보 카드
                VStack(alignment: .leading, spacing: 15) {
                    Text("상세 정보")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.bottom, 5)

                    // 사용자 아이디 Row (특별 컨텍스트 메뉴 포함)
                    UserRow(userId: errorCloudItem.userId, viewModel: viewModel)
                    
                    Divider()
                    
                    // 핵심 정보
                    InfoRowIcon(iconName: "qrcode", title: "Code", value: errorCloudItem.code)
                    InfoRowIcon(iconName: "note.text", title: "Description", value: errorCloudItem.description)
                    InfoRowIcon(iconName: "envelope", title: "Msg", value: errorCloudItem.msg)
                    
                    Divider()
                    
                    // Trace 미리보기
                    TraceRow(traceCn: errorCloudItem.traceCn, isSheetPresented: $isSheetPresented)
                    
                    Divider()

                    // 기타 정보
                    InfoRowIcon(iconName: "link", title: "Request URL", value: errorCloudItem.restUrl)
                    InfoRowIcon(iconName: "calendar", title: "Register DT", value: Util.formatDateTime(errorCloudItem.registerDt))
                    InfoRowIcon(iconName: "info.circle", title: "Request Info", value: Util.formatRequestInfo(errorCloudItem.requestInfo ?? ""))
                    Divider()
                    HStack{
                        Spacer()
                        Button{
                            if errorCloudItem.id  != nil {
                                Task {
                                    print(errorCloudItem.id!)
                                    await viewModel.deleteError(id: errorCloudItem.id!) 
                                }
                            }
                            
                        }label:{
                            Image(systemName: "trash.fill")
                            Text("Delete Data")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColor.destructive) // 버튼 배경색을 빨간색으로 변경하여 삭제 액션 강조
                        .controlSize(.large) // 중요한 버튼이므로 크기 키우기 (선택 사항)
                    }
                }
                .padding()                
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
       // .background(Color(.secondarySystemBackground)) // 전체 배경색
        
        // MARK: - Trace Sheet
        .sheet(isPresented: $isSheetPresented) {
            VStack {
                CloseButton(isPresented: $isSheetPresented)
                Text("Trace 상세")
                    .font(.headline)
                
                ScrollView([.horizontal, .vertical]) {
                    Text(errorCloudItem.traceCn ?? "")
                        .font(AppFont.mono) // Trace는 고정폭 폰트 사용
                        .textSelection(.enabled) // 텍스트 선택 가능
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            //    .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        
        // MARK: - Navigation Bar Title/Subtitle
        #if os(iOS)
        .navigationTitle("에러 상세") 
        #elseif os(macOS)
        .navigationTitle(Util.formatDateTime(errorCloudItem.registerDt))
        #endif
    }
}
/**
 Trace 상세 보기 Row
 */
struct TraceRow: View {
    var traceCn: String?
    @Binding var isSheetPresented: Bool

    var body: some View {
        HStack {
            Image(systemName: "ladybug")
                .foregroundColor(AppColor.error)
                .frame(width: 20)
            Text("Trace:")
                .fontWeight(.medium)
            Spacer()
            
            // 미리보기 텍스트
            Text(traceCn ?? "N/A")
                .foregroundColor(.gray)
                .font(AppFont.mono) // 고정폭 폰트
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 150, alignment: .trailing) // 최대 너비 지정
            
            // 상세 보기 버튼
            Button("상세 보기") {
                isSheetPresented = true
            }
            .buttonStyle(.plain)
            .foregroundColor(AppColor.link)
        }
        .padding(.vertical, 5)
    }
}
// MARK: - Sub Views
/**
 공통 정보 표시 Row
 */
struct InfoRowIcon: View {
    var iconName: String
    var title: String
    var value: String?

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(AppColor.icon)
                .frame(width: 20) // 아이콘 정렬
            Text("\(title):")
                .fontWeight(.medium)
            Spacer()
            Text(value ?? "N/A")
                .foregroundColor(value?.isEmpty == false ? .primary : .secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 5)
    }
}
/**
 사용자 ID Row (복사/로그 다운로드 컨텍스트 메뉴 포함)
 */
struct UserRow: View {
    var userId: String?
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .foregroundColor(AppColor.userIcon)
                .frame(width: 20)
            Text("사용자 아이디:")
                .fontWeight(.medium)
            Spacer()
            Text(userId ?? "N/A")
                .foregroundColor(.secondary)
                .textSelection(.enabled) // ID 선택 가능하게
            
            #if os(macOS)
            // Log Download 버튼 (macOS에서 강조)
            
            Button {
                if userId != "" {
                    Task {
                        let fileURL = try await viewModel.downloadUserLog(userId ?? "")
                        NSWorkspace.shared.open(fileURL)
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.down.fill")
                Text("Log Download")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            #endif
        }
        .padding(.vertical, 5)
        .contextMenu {
            Button("Copy User ID") {
                Util.copyToClipboard(userId ?? "")
            }
            #if os(macOS)
            Button("Log Download & Open") {
                Task {
                    let fileURL = try await viewModel.downloadUserLog(userId ?? "")
                    NSWorkspace.shared.open(fileURL)
                }
            }
            #endif
        }
    }
}

 
#Preview {
    ForEach(0..<1){idx in
        ErrorCloudItemView(viewModel:ViewModel(),errorCloudItem: ErrorCloudItem(
            code: "code\(idx)",
            description: "description\(idx)",
            msg: "msg\(idx)",
            registerDt : Util.getCurrentDateString(),
            requestInfo: "requestInfo",
            restUrl: "restUrl",
            traceCn: "traceCn",
            userId: "userId\(idx)"
        ))
    }
}
