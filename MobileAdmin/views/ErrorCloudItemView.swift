import SwiftUI


struct ErrorCloudItemView: View {
    let errorCloudItem: ErrorCloudItem
    @ObservedObject var toastManager: ToastManager
    
    var body: some View {
        ScrollView {
            VStack{
                Section(header: Text("상세 정보").font(.headline)) {
                    InfoRow(title: "User ID:", value: errorCloudItem.userId ?? "")
                        .contextMenu{
                            Button("Copy"){
                                Util.copyToClipboard(errorCloudItem.userId ?? "")
                                if errorCloudItem.userId != nil {
                                    toastManager.showToast(message: "copy complete : \(errorCloudItem.userId ?? "")")
                                }
                            }
                            Button("View LogInfo"){
                                if errorCloudItem.userId != nil {
                                    toastManager.showToast(message: errorCloudItem.userId ?? "")
                                }
                            }
                        }
                    Divider()
                    InfoRow(title: "Code:", value: errorCloudItem.code ?? "")
                    Divider()
                    InfoRow(title: "Description", value: errorCloudItem.description ?? "")
                    Divider()
                    InfoRow(title: "Msg", value: errorCloudItem.msg ?? "")
                    Divider()
                    InfoRow(title: "Trace", value: errorCloudItem.traceCn ?? "")
                    Divider()
                    InfoRow(title: "Reqest URL", value: errorCloudItem.restUrl ?? "")
                    Divider()
                    InfoRow(title: "Register DT", value: Util.formatDateTime(from:errorCloudItem.registerDt))
                    Divider()
                    InfoRow(title: "Request Info", value: Util.formatRequestInfo(errorCloudItem.requestInfo ?? ""))
                    Divider()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
#if os(iOS)
        .navigationTitle(Util.formatDateTime(from:errorCloudItem.registerDt))
#elseif os(macOS)
        .navigationSubtitle(Util.formatDateTime(from:errorCloudItem.registerDt))
#endif
    }
}

