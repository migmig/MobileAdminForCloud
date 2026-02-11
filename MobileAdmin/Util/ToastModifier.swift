import SwiftUI

struct ToastModifier: ViewModifier {
     @ObservedObject var toastManager: ToastManager

    func body(content:Content) -> some View{
        ZStack{
            content
            if toastManager.isShowing{
                VStack{
                    Spacer()
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.white)
                            .font(AppFont.listTitle)
                        Text(toastManager.message)
                            .font(AppFont.listSubtitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(AppSpacing.lg)
                    .background(AppColor.toastGradient)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.isShowing)
            }
        }
    }
}

extension View{
    func toastManager(toastManager: ToastManager) -> some View{
        self.modifier(ToastModifier(toastManager: toastManager))
    }
}
 
