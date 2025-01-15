import SwiftUI
 

struct ErrorCloudItemView: View {
    let errorCloudItem: ErrorCloudItem
    @State private var isSheetPresented:Bool = false
    var body: some View {
        ScrollView {
            VStack{
                Section(header: Text("상세 정보").font(.headline)) {
                    InfoRow(title: "User ID:", value: errorCloudItem.userId ?? "")
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
                        Text(errorCloudItem.traceCn ?? "")
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .onTapGesture {
                                isSheetPresented = true
                            }
                        .frame(width:200)
                    }
                    Divider()
                    InfoRow(title: "Reqest URL", value: errorCloudItem.restUrl ?? "")
                    Divider()
                    InfoRow(title: "Register DT", value: Util.formatDateTime(errorCloudItem.registerDt))
                    Divider()
                    InfoRow(title: "Request Info", value: Util.formatRequestInfo(errorCloudItem.requestInfo ?? ""))
                    Divider()
                }
                .sheet(isPresented: $isSheetPresented){
                    CloseButton(isPresented: $isSheetPresented)
                    ScrollView([.horizontal, .vertical]){
                        VStack(alignment:.leading){
                            Text(errorCloudItem.traceCn ?? "")
                                .padding()
                        }
                    }
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
