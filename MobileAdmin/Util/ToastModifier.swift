import SwiftUI

struct ToastModifier: ViewModifier {
     @ObservedObject var toastManager: ToastManager
    
    func body(content:Content) -> some View{
        ZStack{
            content
            if toastManager.isShowing{
                VStack{
                    Spacer()
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.white)
                            .padding(.trailing, 8)
                        Text(toastManager.message)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .transition(.move(edge:.bottom).combined(with:.opacity))
                        Spacer()
                    }
                    .padding()
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(40)
                } // VStack
               // .animation(.easeInOut)
            }
        }
    }
}

extension View{
    func toastManager(toastManager: ToastManager) -> some View{
        self.modifier(ToastModifier(toastManager: toastManager))
    }
}
 
