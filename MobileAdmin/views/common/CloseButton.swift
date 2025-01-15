//
//  CloseButton.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 1/15/25.
//

import SwiftUI

struct CloseButton: View {
    @Binding var isPresented:Bool
    var body: some View {
        HStack{
            Spacer()
            Button(action:{
                isPresented = false
            }){
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    CloseButton(isPresented: .constant(true))
}
