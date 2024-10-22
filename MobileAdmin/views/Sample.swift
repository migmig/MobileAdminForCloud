//
//  Sample.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/21/24.
//
import SwiftUI

struct User: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let profileImage: String
    let isOnline: Bool
}

struct ContentView: View {
    let users: [User] = [
        User(name: "John Doe", age: 28, profileImage: "person.fill", isOnline: true),
        User(name: "Emily Smith", age: 24, profileImage: "person.fill", isOnline: false),
        User(name: "Michael Brown", age: 35, profileImage: "person.fill", isOnline: true)
    ]
    
    var body: some View {
         
        Menu(/*@START_MENU_TOKEN@*/"Menu"/*@END_MENU_TOKEN@*/) {
            /*@START_MENU_TOKEN@*/Text("Menu Item 1")/*@END_MENU_TOKEN@*/
            /*@START_MENU_TOKEN@*/Text("Menu Item 2")/*@END_MENU_TOKEN@*/
            Menu(/*@START_MENU_TOKEN@*/"Menu"/*@END_MENU_TOKEN@*/) {
                /*@START_MENU_TOKEN@*/Text("Menu Item 1")/*@END_MENU_TOKEN@*/
                /*@START_MENU_TOKEN@*/Text("Menu Item 2")/*@END_MENU_TOKEN@*/
                Menu(/*@START_MENU_TOKEN@*/"Menu"/*@END_MENU_TOKEN@*/) {
                    /*@START_MENU_TOKEN@*/Text("Menu Item 1")/*@END_MENU_TOKEN@*/
                    /*@START_MENU_TOKEN@*/Text("Menu Item 2")/*@END_MENU_TOKEN@*/
                    Menu(/*@START_MENU_TOKEN@*/"Menu"/*@END_MENU_TOKEN@*/) {
                        /*@START_MENU_TOKEN@*/Text("Menu Item 1")/*@END_MENU_TOKEN@*/
                        /*@START_MENU_TOKEN@*/Text("Menu Item 2")/*@END_MENU_TOKEN@*/
                        /*@START_MENU_TOKEN@*/Text("Menu Item 3")/*@END_MENU_TOKEN@*/
                    }
                }
            }
        }
        
    }
}

#Preview {
    ContentView()
}
