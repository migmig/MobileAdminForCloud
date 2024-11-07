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
                    HStack{
                        Text("Trace")
                        Spacer()
                        NavigationLink(value:errorCloudItem.traceCn){
                            Text(errorCloudItem.traceCn ?? "")
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        .frame(width:200)
                        .navigationDestination(for: String.self){value in
                            ScrollView([.horizontal, .vertical]){
                                VStack(alignment:.leading){
                                    Text(value)
                                        .padding()
                                }
                            }
                        }
                    }
//                    InfoRow(title: "Trace", value: errorCloudItem.traceCn ?? "")
                    Divider()
                    InfoRow(title: "Reqest URL", value: errorCloudItem.restUrl ?? "")
                    Divider()
                    InfoRow(title: "Register DT", value: Util.formatDateTime(errorCloudItem.registerDt))
                    Divider()
                    InfoRow(title: "Request Info", value: Util.formatRequestInfo(errorCloudItem.requestInfo ?? ""))
                    Divider()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
#if os(iOS)
        .navigationTitle(Util.formatDateTime(errorCloudItem.registerDt))
#elseif os(macOS)
        .navigationSubtitle(Util.formatDateTime(errorCloudItem.registerDt))
#endif
    }
}
#Preview{
    ErrorCloudItemView(errorCloudItem: ErrorCloudItem(), toastManager: ToastManager())
}
