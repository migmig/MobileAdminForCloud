//
//  Sample.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/21/24.
//
import SwiftUI
import UniformTypeIdentifiers

struct User: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let profileImage: String
    let isOnline: Bool
}
struct FileInfo: Identifiable {
    var id: String { name }
    let name: String
    let fileType: UTType
}

struct ContentView: View {
    @State var user:User?
    @State var isShowingSheet = false
    @State private var alertDetails: FileInfo?
    @State var isShowDialog = false
    @State var isShowingPopover = false
    @State var showSettings = false
    @State var placeholder = ""
    @State var sliderValue = 0.0
    var body: some View {
        VStack {
#if os(iOS)
            Button("Show Action Sheet", action: {
                isShowingSheet = true
            })
            .actionSheet(isPresented: $isShowingSheet) {
                ActionSheet(
                    title: Text("Permanently erase the items in the Trash?"),
                    message: Text("You can't undo this action."),
                    buttons:[
                        .destructive(Text("Empty Trash"),
                                     action: {}),
                        .cancel()
                    ]
                )}
            Divider()
#endif
            Button("Show Alert") {
                alertDetails = FileInfo(name: "MyImageFile.png",
                                        fileType: .png)
            }
            .alert(item: $alertDetails) { details in
                Alert(title: Text("Import Complete"),
                      message: Text("""
                               Imported \(details.name) \n File
                               type: \(details.fileType.description).
                               """),
                      dismissButton: .default(Text("Dismiss")))
            }
            Divider()
            
            Button("confirm") {
                isShowDialog = true
            }
            
            .confirmationDialog("", isPresented: $isShowDialog) {
                Text("Are you sure?")
            }
            Divider()
            Button("Show Popover") {
                self.isShowingPopover = true
            }
            .popover(
                isPresented: $isShowingPopover, arrowEdge: .bottom
            ) {
                Text("Popover Content")
                    .padding()
            }
            Divider()
            Button("View Settings") {
                showSettings = true
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            Divider()
            VStack(spacing: 20) {
                Button(action: {}) {
                    Text("Regular Button")
                }
                VStack {
                    Button(action: {}) {
                        Text("Accented Button")
                    }
                    HStack {
                        Text("Accented Slider")
                        Slider(value: $sliderValue, in: -100...100, step: 0.1)
                    }
                }
                .accentColor(.purple)
            }
            Divider()
            Button("Show Part Details") {
                user = User(name: "John Doe", age: 30, profileImage: "profile", isOnline: true)
                //Text("Show Part Details")
            }
            .sheet(item:$user,onDismiss: {
                print("onDismiss")
            }, content: { user in
                Text("User: \(user.name)")
            })
            Divider()
            Table(of: User.self){
                TableColumn("Name"){
                    Text($0.name)
                }
                TableColumn("Age"){
                    Text("\($0.age)")
                }
            } rows:{
                TableRow(User(name: "John Doe", age: 30, profileImage: "profile", isOnline: true))
                TableRow(User(name: "Jane Doe", age: 25, profileImage: "profile", isOnline: false))
                TableRow(User(name: "Jane Doe", age: 25, profileImage: "profile", isOnline: false))
            }
        }
    }
}

#Preview{
    //ContentView()
    testView()
}

struct testView:View{
    var body: some View{
        
        ZStack {
            Color.red
            Text("Hello, World!")
                .foregroundColor(.white)
        }
    }
}
 
