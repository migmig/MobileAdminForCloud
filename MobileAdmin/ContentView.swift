//
//  ContentView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 10/8/24.
//

import SwiftUI


struct ContentView: View {
    @StateObject var viewModel = ToastViewModel()
    @State private var toast:Toast?
    var body: some View {
        VStack(spacing: 3.0) {
             
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
          
            Text("\(toast?.noticeCn ?? "Hello, world!")")
            
        }.padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/).onTapGesture {
            toast = Toast()
            viewModel.fetchToasts{ result in
               
                toast = result
            }
        }
        
    }
}

#Preview {
    ContentView()
}
