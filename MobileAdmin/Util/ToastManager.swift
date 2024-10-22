import SwiftUI

class ToastManager: ObservableObject {
    @Published var isShowing:Bool = false
    @Published var  message:String = ""
    
    func showToast(message:String, duration:Double = 2.0){
        self.message = message
        withAnimation{
            self.isShowing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation{
                self.isShowing = false
            } 
        }
    }
}
