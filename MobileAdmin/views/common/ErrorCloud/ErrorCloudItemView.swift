import SwiftUI
#if os(macOS)
import AppKit
#endif
struct ErrorCloudItemView: View {
    @EnvironmentObject var errorViewModel: ErrorViewModel
    var errorCloudItem: ErrorCloudItem
    @State private var isSheetPresented: Bool = false
    @State private var isRequestInfoSheetPresented: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // MARK: - 에러 요약 헤더
                errorSummaryHeader

                // MARK: - 사용자 정보
                CardView(title: "사용자", systemImage: "person.crop.circle") {
                    UserRow(userId: errorCloudItem.userId)
                }

                // MARK: - 핵심 정보
                CardView(title: "오류 정보", systemImage: "exclamationmark.triangle") {
                    VStack(spacing: 0) {
                        InfoRowIcon(iconName: "qrcode", title: "Code", value: errorCloudItem.code)
                        Divider().padding(.leading, AppIconSize.xs + AppSpacing.sm)
                        InfoRowIcon(iconName: "note.text", title: "Description", value: errorCloudItem.description)
                        Divider().padding(.leading, AppIconSize.xs + AppSpacing.sm)
                        InfoRowIcon(iconName: "envelope", title: "Msg", value: errorCloudItem.msg)
                    }
                }

                // MARK: - Trace
                CardView(title: "Trace", systemImage: "ladybug") {
                    TraceRow(traceCn: errorCloudItem.traceCn, isSheetPresented: $isSheetPresented)
                }

                // MARK: - 요청 정보
                CardView(title: "요청 정보", systemImage: "network") {
                    VStack(spacing: 0) {
                        InfoRowIcon(iconName: "link", title: "Request URL", value: errorCloudItem.restUrl)
                        Divider().padding(.leading, AppIconSize.xs + AppSpacing.sm)
                        InfoRowIcon(iconName: "calendar", title: "Register DT", value: Util.formatDateTime(errorCloudItem.registerDt))
                        Divider().padding(.leading, AppIconSize.xs + AppSpacing.sm)
                        RequestInfoRow(
                            requestInfo: errorCloudItem.requestInfo,
                            isSheetPresented: $isRequestInfoSheetPresented
                        )
                    }
                }

                // MARK: - 삭제
                HStack {
                    Spacer()
                    Button {
                        if let id = errorCloudItem.id {
                            Task { await errorViewModel.deleteError(id: id) }
                        }
                    } label: {
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
            TraceDetailView(traceContent: errorCloudItem.traceCn ?? "")
                #if os(macOS)
                .frame(minWidth: 700, minHeight: 500)
                #endif
        }

        // MARK: - Request Info Sheet
        .sheet(isPresented: $isRequestInfoSheetPresented) {
            RequestInfoDetailView(requestInfo: errorCloudItem.requestInfo ?? "")
                #if os(macOS)
                .frame(minWidth: 700, minHeight: 500)
                #endif
        }

        #if os(iOS)
        .navigationTitle("에러 상세")
        #elseif os(macOS)
        .navigationTitle(Util.formatDateTime(errorCloudItem.registerDt))
        #endif
    }

    // MARK: - 에러 요약 헤더
    private var errorSummaryHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                if let code = errorCloudItem.code, !code.isEmpty {
                    Text(code)
                        .font(AppFont.captionSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Capsule().fill(AppColor.error))
                }
                Spacer()
                if let dt = errorCloudItem.registerDt {
                    Text(Util.formatDateTime(dt))
                        .font(AppFont.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
            }

            Text(errorCloudItem.description ?? errorCloudItem.msg ?? "Unknown Error")
                .font(.system(.body, weight: .semibold))
                .foregroundColor(.primary)
                .textSelection(.enabled)

            if let restUrl = errorCloudItem.restUrl, !restUrl.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "link")
                        .font(AppFont.captionSmall)
                        .foregroundColor(AppColor.icon)
                    Text(restUrl)
                        .font(AppFont.mono)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }

            if let userId = errorCloudItem.userId, !userId.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "person.circle")
                        .font(AppFont.captionSmall)
                        .foregroundColor(AppColor.userIcon)
                    Text(userId)
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .cardShadow()
    }
}

// MARK: - Trace Row
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
            Button { isSheetPresented = true } label: {
                Label("상세 보기", systemImage: "arrow.up.right.square")
                    .font(AppFont.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Request Info Row
struct RequestInfoRow: View {
    var requestInfo: String?
    @Binding var isSheetPresented: Bool

    private var formattedPreview: String {
        Util.formatRequestInfo(requestInfo ?? "")
    }

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "info.circle")
                .foregroundColor(AppColor.icon)
                .font(AppFont.caption)
                .frame(width: AppIconSize.xs)
            Text("Request Info")
                .font(AppFont.caption)
                .foregroundColor(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(formattedPreview)
                    .font(AppFont.mono)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.trailing)
                if requestInfo?.isEmpty == false {
                    Button { isSheetPresented = true } label: {
                        Label("상세 보기", systemImage: "arrow.up.right.square")
                            .font(AppFont.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .contextMenu {
            Button("Copy") { Util.copyToClipboard(formattedPreview) }
        }
    }
}

// MARK: - InfoRowIcon
struct InfoRowIcon: View {
    var iconName: String
    var title: String
    var value: String?

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: iconName)
                .foregroundColor(AppColor.icon)
                .font(AppFont.caption)
                .frame(width: AppIconSize.xs)
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
            Button("Copy") { Util.copyToClipboard(value ?? "") }
        }
    }
}

// MARK: - UserRow
struct UserRow: View {
    var userId: String?
    @EnvironmentObject var errorViewModel: ErrorViewModel

    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .foregroundColor(AppColor.userIcon)
                .frame(width: AppIconSize.xs)
            Text("사용자 아이디:")
                .fontWeight(.medium)
            Spacer()
            Text(userId ?? "N/A")
                .foregroundColor(.secondary)
                .textSelection(.enabled)

            #if os(macOS)
            Button {
                guard let uid = userId, !uid.isEmpty else { return }
                Task {
                    let fileURL = try await errorViewModel.downloadUserLog(uid)
                    NSWorkspace.shared.open(fileURL)
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
            Button("Copy User ID") { Util.copyToClipboard(userId ?? "") }
            #if os(macOS)
            Button("Log Download & Open") {
                guard let uid = userId, !uid.isEmpty else { return }
                Task {
                    let fileURL = try await errorViewModel.downloadUserLog(uid)
                    NSWorkspace.shared.open(fileURL)
                }
            }
            #endif
        }
    }
}

#Preview {
    ErrorCloudItemView(errorCloudItem: ErrorCloudItem(
        code: "ERR_500",
        description: "NullPointerException",
        msg: "msg",
        registerDt: Util.getCurrentDateString(),
        requestInfo: "{\"userId\":\"testUser\"}",
        restUrl: "/api/v1/admin/users",
        traceCn: "java.lang.NullPointerException",
        userId: "admin01"
    ))
    .environmentObject(ErrorViewModel())
}
