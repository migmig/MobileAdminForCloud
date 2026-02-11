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
            VStack(spacing: AppSpacing.md) {
                // MARK: - 사용자 정보
                CardView(title: "사용자", systemImage: "person.crop.circle") {
                    UserRow(userId: errorCloudItem.userId, viewModel: viewModel)
                }

                // MARK: - 핵심 정보
                CardView(title: "오류 정보", systemImage: "exclamationmark.triangle") {
                    InfoRowIcon(iconName: "qrcode", title: "Code", value: errorCloudItem.code)
                    InfoRowIcon(iconName: "note.text", title: "Description", value: errorCloudItem.description)
                    InfoRowIcon(iconName: "envelope", title: "Msg", value: errorCloudItem.msg)
                }

                // MARK: - Trace
                CardView(title: "Trace", systemImage: "ladybug") {
                    TraceRow(traceCn: errorCloudItem.traceCn, isSheetPresented: $isSheetPresented)
                }

                // MARK: - 요청 정보
                CardView(title: "요청 정보", systemImage: "network") {
                    InfoRowIcon(iconName: "link", title: "Request URL", value: errorCloudItem.restUrl)
                    InfoRowIcon(iconName: "calendar", title: "Register DT", value: Util.formatDateTime(errorCloudItem.registerDt))
                    InfoRowIcon(iconName: "info.circle", title: "Request Info", value: Util.formatRequestInfo(errorCloudItem.requestInfo ?? ""))
                }

                // MARK: - 삭제
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
                        Label("Delete Data", systemImage: "trash.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.destructive)
                    .controlSize(.large)
                }
            }
            .padding(AppSpacing.lg)
        }
        
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
            Text(traceCn ?? "N/A")
                .foregroundColor(.secondary)
                .font(AppFont.mono)
                .lineLimit(2)
                .truncationMode(.tail)

            Spacer()

            Button {
                isSheetPresented = true
            } label: {
                Label("상세 보기", systemImage: "arrow.up.right.square")
                    .font(AppFont.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, AppSpacing.xs)
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
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: iconName)
                .foregroundColor(AppColor.icon)
                .font(AppFont.caption)
                .frame(width: 20)
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value ?? "N/A")
                .font(AppFont.body)
                .foregroundColor(value?.isEmpty == false ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, AppSpacing.xs)
        .contextMenu {
            Button("Copy") {
                Util.copyToClipboard(value ?? "")
            }
        }
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
        .padding(.vertical, AppSpacing.xs)
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
